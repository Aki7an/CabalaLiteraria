/**
 * Receptor de trazas CifraLetra (PlayFab webhook o POST del juego).
 * Hoja: "CifraLetra Datos Partidas Jugadores"
 *
 * Despliegue: Implementar > Nueva implementación > Aplicación web
 *   - Ejecutar como: yo (aki7an@gmail.com)
 *   - Quién tiene acceso: Cualquiera
 * La URL /exec se pega en PlayFab (webhook) y en play_fab.gd (GOOGLE_SHEETS_WEBHOOK).
 */
const SHEET_TITLE = "CifraLetra Datos Partidas Jugadores";
const SPREADSHEET_ID = "18czTtnTTUFsM6L30Y4SA572RSleLZXtePXx7ngNU0tw";
const WEBHOOK_KEY = "cl-partidas-7f3a9c2e";
const PARTIDAS_SHEET = "Partidas";
const PULSACIONES_SHEET = "Pulsaciones";
const CELL_MAX = 45000;

const PARTIDAS_HEADERS = [
	"RecibidoUTC",
	"Evento",
	"PlayFabId",
	"SessionId",
	"PuzzleId",
	"Jugador",
	"Categoria",
	"Dificultad",
	"Modo",
	"DuracionSeg",
	"Locale",
	"Version",
	"Plataforma",
	"ChunkIndex",
	"ChunkCount",
	"EventCount",
	"EventosJSON",
];

const PULSACIONES_HEADERS = [
	"RecibidoUTC",
	"PlayFabId",
	"SessionId",
	"PuzzleId",
	"IdEvento",
	"Accion",
	"TiempoMs",
	"TiempoPartidaSeg",
	"Letra",
	"Numero",
	"Orden",
	"DetalleJSON",
];

function doGet(e) {
	if (!_keyOk(e)) {
		return _json({ ok: false, error: "forbidden" });
	}
	return _json({ ok: true, sheet: SHEET_TITLE });
}

function doPost(e) {
	if (!_keyOk(e)) {
		return _json({ ok: false, error: "forbidden" });
	}
	var raw = "";
	if (e && e.postData && e.postData.contents) {
		raw = String(e.postData.contents);
	}
	if (!raw) {
		return _json({ ok: false, error: "empty_body" });
	}
	var parsed;
	try {
		parsed = JSON.parse(raw);
	} catch (err) {
		return _json({ ok: false, error: "invalid_json" });
	}
	var items = _normalizePayload(parsed);
	var ss = _openSpreadsheet();
	var partidas = _ensureSheet(ss, PARTIDAS_SHEET, PARTIDAS_HEADERS);
	var pulsaciones = _ensureSheet(ss, PULSACIONES_SHEET, PULSACIONES_HEADERS);
	var received = new Date().toISOString();
	var partidaRows = [];
	var pulseRows = [];
	for (var i = 0; i < items.length; i++) {
		var item = items[i];
		partidaRows.push(_partidaRow(received, item));
		var events = item.events;
		if (events && events.length) {
			for (var j = 0; j < events.length; j++) {
				pulseRows.push(_pulseRow(received, item, events[j]));
			}
		}
	}
	if (partidaRows.length) {
		partidas.getRange(partidas.getLastRow() + 1, 1, partidaRows.length, PARTIDAS_HEADERS.length).setValues(partidaRows);
	}
	if (pulseRows.length) {
		pulsaciones.getRange(pulsaciones.getLastRow() + 1, 1, pulseRows.length, PULSACIONES_HEADERS.length).setValues(pulseRows);
	}
	return _json({
		ok: true,
		partidas: partidaRows.length,
		pulsaciones: pulseRows.length,
	});
}

function _keyOk(e) {
	var key = "";
	if (e && e.parameter && e.parameter.k) {
		key = String(e.parameter.k);
	}
	if (!key && e && e.postData && e.postData.contents) {
		try {
			var parsed = JSON.parse(String(e.postData.contents));
			if (parsed && typeof parsed === "object") {
				key = String(parsed.k || parsed.webhook_key || "");
			}
		} catch (err) {}
	}
	return key === WEBHOOK_KEY;
}

function _normalizePayload(parsed) {
	if (Object.prototype.toString.call(parsed) === "[object Array]") {
		var out = [];
		for (var i = 0; i < parsed.length; i++) {
			out = out.concat(_normalizePayload(parsed[i]));
		}
		return out;
	}
	if (!parsed || typeof parsed !== "object") {
		return [];
	}
	if (parsed.EventData && typeof parsed.EventData === "object") {
		return [_fromPlayStream(parsed)];
	}
	if (parsed.events && Object.prototype.toString.call(parsed.events) === "[object Array]") {
		return [_fromGamePayload(parsed)];
	}
	if (parsed.EventName || parsed.eventName || parsed.session_id || parsed.SessionId) {
		return [_fromPlayStream(parsed)];
	}
	return [_fromGamePayload(parsed)];
}

function _fromGamePayload(data) {
	return {
		eventName: data.EventName || "puzzle_solve_trace",
		playFabId: data.PlayFabId || data.playfab_id || "",
		sessionId: data.session_id || "",
		puzzleId: data.puzzle_id,
		player: data.player || "",
		category: data.category || "",
		difficulty: data.difficulty,
		mode: data.game_mode || "",
		duration: data.duration_sec,
		locale: data.locale || "",
		version: data.client_ver || "",
		platform: data.platform || "",
		chunkIndex: data.chunk_index,
		chunkCount: data.chunk_count,
		eventCount: data.event_count || (data.events ? data.events.length : 0),
		events: data.events || [],
		raw: data,
	};
}

function _fromPlayStream(evt) {
	var body = evt.EventData || evt;
	var name = String(evt.EventName || evt.eventName || body.EventName || "");
	if (name.indexOf(".") >= 0) {
		name = name.split(".").pop();
	}
	return {
		eventName: name || "puzzle_solve_trace",
		playFabId: evt.PlayFabId || evt.EntityId || body.PlayFabId || "",
		sessionId: body.session_id || "",
		puzzleId: body.puzzle_id,
		player: body.player || "",
		category: body.category || "",
		difficulty: body.difficulty,
		mode: body.game_mode || "",
		duration: body.duration_sec,
		locale: body.locale || "",
		version: body.client_ver || "",
		platform: body.platform || "",
		chunkIndex: body.chunk_index,
		chunkCount: body.chunk_count,
		eventCount: body.event_count || (body.events ? body.events.length : 0),
		events: body.events || [],
		raw: body,
	};
}

function _partidaRow(received, item) {
	var json = JSON.stringify(item.raw || {});
	if (json.length > CELL_MAX) {
		json = json.substring(0, CELL_MAX);
	}
	return [
		received,
		item.eventName || "",
		item.playFabId || "",
		item.sessionId || "",
		item.puzzleId == null ? "" : item.puzzleId,
		item.player || "",
		item.category || "",
		item.difficulty == null ? "" : item.difficulty,
		item.mode || "",
		item.duration == null ? "" : item.duration,
		item.locale || "",
		item.version || "",
		item.platform || "",
		item.chunkIndex == null ? "" : item.chunkIndex,
		item.chunkCount == null ? "" : item.chunkCount,
		item.eventCount == null ? "" : item.eventCount,
		json,
	];
}

function _pulseRow(received, item, ev) {
	ev = ev || {};
	var copy = {};
	for (var key in ev) {
		if (!ev.hasOwnProperty(key)) continue;
		if (key === "id" || key === "action" || key === "t_ms" || key === "t_game_sec" || key === "letter" || key === "numero" || key === "orden") {
			continue;
		}
		copy[key] = ev[key];
	}
	return [
		received,
		item.playFabId || "",
		item.sessionId || "",
		item.puzzleId == null ? "" : item.puzzleId,
		ev.id == null ? "" : ev.id,
		ev.action || "",
		ev.t_ms == null ? "" : ev.t_ms,
		ev.t_game_sec == null ? "" : ev.t_game_sec,
		ev.letter || "",
		ev.numero == null ? "" : ev.numero,
		ev.orden == null ? "" : ev.orden,
		JSON.stringify(copy),
	];
}

function _openSpreadsheet() {
	try {
		if (SPREADSHEET_ID) {
			return SpreadsheetApp.openById(SPREADSHEET_ID);
		}
	} catch (err) {
	}
	var files = DriveApp.getFilesByName(SHEET_TITLE);
	if (files.hasNext()) {
		return SpreadsheetApp.open(files.next());
	}
	return SpreadsheetApp.create(SHEET_TITLE);
}

function _ensureSheet(ss, name, headers) {
	var sheet = ss.getSheetByName(name);
	if (!sheet) {
		sheet = ss.insertSheet(name);
	}
	if (sheet.getLastRow() === 0) {
		sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
		sheet.setFrozenRows(1);
	}
	return sheet;
}

function _json(obj) {
	return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
