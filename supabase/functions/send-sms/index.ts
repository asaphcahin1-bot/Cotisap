// Supabase Auth "Send SMS" hook — remplace l'envoi SMS par défaut de
// Supabase (Twilio) par un appel à l'API Orange SMS Côte d'Ivoire, voir
// DECISIONS.md, "Authentification par SMS : Orange CI plutôt que
// Twilio" — même service (un code par SMS), fournisseur local
// nettement moins cher pour ce marché (10-50 FCFA/SMS chez Orange
// contre ~150 FCFA chez Twilio).
//
// Secrets requis — à définir dans Supabase Dashboard → Edge Functions
// → Manage secrets, JAMAIS dans ce fichier ni commités dans le dépôt :
//   SEND_SMS_HOOK_SECRET   — fourni par Supabase à la configuration du
//                            hook (Authentication → Hooks → Send SMS
//                            hook), format "v1,whsec_..."
//   ORANGE_CLIENT_ID       — Orange Developer, page de l'application
//   ORANGE_CLIENT_SECRET   — idem
//   ORANGE_SENDER_NUMBER   — le numéro Orange CI utilisé comme
//                            expéditeur, format international SANS le
//                            "+" (ex. "2250700000000")
//
// Déploiement : `supabase functions deploy send-sms --no-verify-jwt`
// — le hook est appelé par Supabase Auth lui-même (jamais par un
// utilisateur connecté de l'app), la vérification se fait par la
// signature du webhook ci-dessous, pas par un JWT applicatif.

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

const ORANGE_TOKEN_URL = "https://api.orange.com/oauth/v3/token";
const ORANGE_SMS_BASE_URL = "https://api.orange.com/smsmessaging/v1/outbound";

interface SendSmsPayload {
  user: { phone?: string };
  sms: { otp: string };
}

function reponseErreur(httpCode: number, message: string): Response {
  return new Response(
    JSON.stringify({ error: { http_code: httpCode, message } }),
    { status: httpCode, headers: { "Content-Type": "application/json" } },
  );
}

// Un numéro peut arriver avec ou sans "+" selon la source (Supabase,
// variable d'environnement saisie à la main) — toujours retiré ici,
// puis reconstruit au format "tel:+..." attendu par Orange, pour ne
// jamais se retrouver avec un double "+".
function numeroPropre(numero: string): string {
  return numero.replace(/^\+/, "").trim();
}

// Échange le Client ID / Secret Orange contre un jeton d'accès (valable
// 1h côté Orange) — jamais mis en cache ici : un appel par SMS envoyé
// reste largement sous la limite de 5 requêtes/seconde d'Orange pour
// l'usage réel de ce projet (un agent à la fois, jamais un envoi de
// masse).
async function obtenirJetonOrange(
  clientId: string,
  clientSecret: string,
): Promise<string> {
  const basic = btoa(`${clientId}:${clientSecret}`);
  const resp = await fetch(ORANGE_TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json",
    },
    body: "grant_type=client_credentials",
  });
  if (!resp.ok) {
    throw new Error(`Orange OAuth ${resp.status} : ${await resp.text()}`);
  }
  const data = await resp.json();
  return data.access_token as string;
}

async function envoyerSmsOrange(params: {
  accessToken: string;
  numeroExpediteur: string;
  numeroDestinataire: string;
  message: string;
}): Promise<void> {
  const senderTel = `tel:+${numeroPropre(params.numeroExpediteur)}`;
  const url = `${ORANGE_SMS_BASE_URL}/${encodeURIComponent(senderTel)}/requests`;
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${params.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      outboundSMSMessageRequest: {
        address: `tel:+${numeroPropre(params.numeroDestinataire)}`,
        senderAddress: senderTel,
        senderName: "CotisApp",
        outboundSMSTextMessage: { message: params.message },
      },
    }),
  });
  if (!resp.ok) {
    throw new Error(`Orange SMS ${resp.status} : ${await resp.text()}`);
  }
}

Deno.serve(async (req) => {
  const payload = await req.text();
  const headers = Object.fromEntries(req.headers);

  // Vérifie que la requête vient bien de Supabase Auth, pas d'un tiers
  // qui aurait deviné l'URL de cette fonction — jamais d'appel à
  // Orange (donc jamais de coût) sans cette vérification.
  const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!hookSecret) {
    return reponseErreur(500, "SEND_SMS_HOOK_SECRET manquant côté serveur.");
  }

  let user: SendSmsPayload["user"];
  let sms: SendSmsPayload["sms"];
  try {
    const wh = new Webhook(hookSecret.replace("v1,whsec_", ""));
    const verifie = wh.verify(payload, headers) as SendSmsPayload;
    user = verifie.user;
    sms = verifie.sms;
  } catch (_err) {
    return reponseErreur(401, "Signature du webhook invalide.");
  }

  if (!user.phone) {
    return reponseErreur(400, "Aucun numéro de téléphone pour cet utilisateur.");
  }

  const clientId = Deno.env.get("ORANGE_CLIENT_ID");
  const clientSecret = Deno.env.get("ORANGE_CLIENT_SECRET");
  const numeroExpediteur = Deno.env.get("ORANGE_SENDER_NUMBER");
  if (!clientId || !clientSecret || !numeroExpediteur) {
    return reponseErreur(500, "Identifiants Orange manquants côté serveur.");
  }

  try {
    const accessToken = await obtenirJetonOrange(clientId, clientSecret);
    await envoyerSmsOrange({
      accessToken,
      numeroExpediteur,
      numeroDestinataire: user.phone,
      message: `CotisApp : votre code est ${sms.otp}`,
    });
  } catch (err) {
    console.error("Échec envoi SMS Orange :", err);
    return reponseErreur(500, "Échec de l'envoi du SMS via Orange.");
  }

  return new Response(null, { status: 200 });
});
