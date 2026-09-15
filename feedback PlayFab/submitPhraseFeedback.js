// CloudScript: submitPhraseFeedback
// Premia +1 moneda (VC_CODE) si es la primera vez que el jugador opina esa frase.
// Guarda un flag en PlayerData: FB_<phrase_id> = "1" para evitar repetición del premio.
// Escribe un evento PlayStream "phrase_feedback" con todas las respuestas.

handlers.submitPhraseFeedback = function (args, context) {
  const VC_CODE = "CO";        // <-- tu código de moneda (2 letras, por ej. CO)
  const MAX_COMMENT = 600;     // límite sensato de comentario
  const p = args || {};

  // --- Validaciones y normalización ---
  function clampInt(v, min, max) {
    v = parseInt(v); if (isNaN(v)) v = 0; return Math.max(min, Math.min(max, v));
  }

  function allowedIssue(v, allowed) {
    v = String(v || "");
    return allowed.indexOf(v) >= 0 ? v : "";
  }

  const phraseId = String(p.phrase_id || "").trim();
  if (!phraseId) {
    return { ok: false, error: "phrase_id requerido" };
  }

  const fb = {
    phrase_id: phraseId,
    rating_global:   clampInt(p.rating_global,   0, 5),
    rating_diff:     clampInt(p.rating_difficulty, 0, 5),
    rating_interest: clampInt(p.rating_interest, 0, 5),
    rating_duration: clampInt(p.rating_duration, 0, 5),
    rating_hint1:    clampInt(p.rating_hint1, 0, 5),
    rating_hint2:    clampInt(p.rating_hint2, 0, 5),
    rating_hint3:    clampInt(p.rating_hint3, 0, 5),
    difficulty_issue: allowedIssue(p.difficulty_issue, ["too_easy", "too_hard"]),
    duration_issue:   allowedIssue(p.duration_issue, ["too_short", "too_long"]),
    comment:         String(p.comment || "").substring(0, MAX_COMMENT),
    // extra contexto útil:
    client_ver: String(p.client_ver || ""),
    locale:     String(p.locale || ""),
    platform:   String(p.platform || ""),
    player_name: ""
  };

  try {
    var profile = server.GetPlayerProfile({
      PlayFabId: currentPlayerId,
      ProfileConstraints: { ShowDisplayName: true }
    });
    if (profile && profile.PlayerProfile && profile.PlayerProfile.DisplayName) {
      fb.player_name = String(profile.PlayerProfile.DisplayName);
    }
  } catch (e) {
    fb.player_name = "";
  }

  // --- Escribir evento PlayStream (server-authoritative) ---
  // (Puedes usar también Events/Telemetry; PlayStream es perfecto para queries y reacciones)
  server.WritePlayerEvent({
    PlayFabId: currentPlayerId,
    EventName: "phrase_feedback",
    Body: fb
  });

  // --- Evitar recompensa duplicada por frase ---
  var already = false;
  var userData = server.GetUserData({
    PlayFabId: currentPlayerId,
    Keys: [ "FB_" + phraseId ]
  });

  if (userData.Data && userData.Data["FB_" + phraseId]) {
    already = true;
  }

  var granted = 0;
  if (!already) {
    // Marcar que ya opinó esta frase
    server.UpdateUserData({
      PlayFabId: currentPlayerId,
      Data: { ["FB_" + phraseId]: "1" },
      Permission: "Private"
    });

    // Recompensa (+1)
    server.AddUserVirtualCurrency({
      PlayFabId: currentPlayerId,
      VirtualCurrency: VC_CODE,
      Amount: 1
    });
    granted = 1;
  }

  return { ok: true, granted: granted };
};
