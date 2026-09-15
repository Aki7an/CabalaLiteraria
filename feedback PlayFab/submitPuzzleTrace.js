// CloudScript: submitPuzzleTrace
// Recibe la cabecera de una traza de resolución (el detalle va en WritePlayerEvent chunks).

handlers.submitPuzzleTrace = function (args, context) {
  const p = args || {};
  const phraseId = String(p.puzzle_id || "").trim();
  if (!phraseId) {
    return { ok: false, error: "puzzle_id requerido" };
  }

  const body = {
    puzzle_id: phraseId,
    session_id: String(p.session_id || ""),
    duration_sec: parseInt(p.duration_sec, 10) || 0,
    event_count: parseInt(p.event_count, 10) || 0,
    category: String(p.category || ""),
    difficulty: parseInt(p.difficulty, 10) || 0,
    game_mode: String(p.game_mode || ""),
    locale: String(p.locale || ""),
    client_ver: String(p.client_ver || ""),
    platform: String(p.platform || ""),
  };

  server.WritePlayerEvent({
    PlayFabId: currentPlayerId,
    EventName: "puzzle_solve_trace",
    Body: body
  });

  return { ok: true };
};
