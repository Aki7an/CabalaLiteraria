/**
 * CifraLetra — valoraciones PlayFab → Google Sheets
 * Cuenta: aki7an@gmail.com
 *
 * 1. Crea una hoja en Drive (esa cuenta) y nómbrala como quieras.
 * 2. Extensiones → Apps Script → pega este archivo.
 * 3. Project Settings → Script properties:
 *      WEBHOOK_SECRET = una clave larga que inventes
 * 4. Ejecuta una vez setupSheet() (Run) y autoriza.
 * 5. Implementar → Nueva implementación → Aplicación web
 *      Ejecutar como: Yo
 *      Quién tiene acceso: Cualquiera
 *    Copia la URL.
 * 6. PlayFab Game Manager → Title settings → Webhooks
 *      URL: esa URL + ?secret=WEBHOOK_SECRET
 *      (si PlayFab no deja cabeceras custom, el secreto va en la query)
 *      Event Name: player_phrase_feedback
 * 7. (Opcional) Trigger diario: importarInsightsUnaVezAlDia
 *      Requiere propiedades Azure: INSIGHTS_TENANT_ID, INSIGHTS_CLIENT_ID, INSIGHTS_CLIENT_SECRET
 *      TITLE_ID por defecto 1BC2FD
 */

var TITLE_ID = "1BC2FD";
var SHEET_NAME = "Feedback";
var HEADERS = [
  "Timestamp",
  "Usuario",
  "PlayFabId",
  "phrase_id",
  "global",
  "dificultad",
  "dificultad_issue",
  "interes",
  "duracion",
  "duracion_issue",
  "pista1",
  "pista2",
  "pista3",
  "comentario",
  "locale",
  "plataforma",
  "version",
  "EventId",
];

function setupSheet() {
  var sheet = _sheet();
  sheet.clear();
  sheet.appendRow(HEADERS);
  sheet.setFrozenRows(1);
  sheet.autoResizeColumns(1, HEADERS.length);
}

function doPost(e) {
  var secret = PropertiesService.getScriptProperties().getProperty("WEBHOOK_SECRET") || "";
  var headerSecret = "";
  if (e && e.headers) {
    headerSecret = e.headers["X-Feedback-Secret"] || e.headers["x-feedback-secret"] || "";
  }
  var querySecret = (e && e.parameter && e.parameter.secret) ? String(e.parameter.secret) : "";
  if (secret !== "" && headerSecret !== secret && querySecret !== secret) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: "unauthorized" }))
      .setMimeType(ContentService.MimeType.JSON);
  }
  var raw = (e && e.postData && e.postData.contents) ? e.postData.contents : "";
  var parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: "bad_json" }))
      .setMimeType(ContentService.MimeType.JSON);
  }
  var events = Array.isArray(parsed) ? parsed : [parsed];
  var added = 0;
  for (var i = 0; i < events.length; i++) {
    if (_appendEvent(events[i])) {
      added++;
    }
  }
  return ContentService.createTextOutput(JSON.stringify({ ok: true, added: added }))
    .setMimeType(ContentService.MimeType.JSON);
}

function importarInsightsUnaVezAlDia() {
  var props = PropertiesService.getScriptProperties();
  var tenant = props.getProperty("INSIGHTS_TENANT_ID") || "";
  var clientId = props.getProperty("INSIGHTS_CLIENT_ID") || "";
  var clientSecret = props.getProperty("INSIGHTS_CLIENT_SECRET") || "";
  var titleId = props.getProperty("TITLE_ID") || TITLE_ID;
  if (!tenant || !clientId || !clientSecret) {
    throw new Error("Faltan INSIGHTS_TENANT_ID / INSIGHTS_CLIENT_ID / INSIGHTS_CLIENT_SECRET");
  }
  var token = _insightsToken(tenant, clientId, clientSecret);
  var query =
    "['events.all']" +
    "| where Timestamp > ago(2d)" +
    '| where FullName_Name == "phrase_feedback"' +
    "| lookup kind=leftouter (" +
    "  ['events.all']" +
    "  | where Timestamp > ago(90d)" +
    '  | where FullName_Name in ("player_display_name_changed", "player_logged_in")' +
    "  | extend usuario = coalesce(tostring(EventData.DisplayName), tostring(EventData.TitleDisplayName))" +
    "  | where isnotempty(usuario)" +
    "  | summarize usuario = arg_max(Timestamp, usuario) by Entity_Id" +
    ") on Entity_Id" +
    "| project Timestamp, usuario, Entity_Id, EventId, EventData" +
    "| order by Timestamp desc";
  var payload = {
    db: titleId,
    csl: query,
  };
  var response = UrlFetchApp.fetch("https://insights.playfab.com/v1/rest/query", {
    method: "post",
    contentType: "application/json",
    headers: {
      Authorization: "Bearer " + token,
      Accept: "application/json",
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });
  var body = JSON.parse(response.getContentText());
  var table = _kustoPrimaryTable(body);
  if (!table) {
    throw new Error("Insights no devolvió tabla: " + response.getContentText().substring(0, 400));
  }
  var cols = table.Columns || table.columns || [];
  var rows = table.Rows || table.rows || [];
  var added = 0;
  for (var r = 0; r < rows.length; r++) {
    var row = _rowByName(cols, rows[r]);
    var eventData = row.EventData || {};
    if (typeof eventData === "string") {
      try {
        eventData = JSON.parse(eventData);
      } catch (err) {
        eventData = {};
      }
    }
    var event = {
      Timestamp: row.Timestamp,
      EventId: row.EventId,
      PlayFabId: row.Entity_Id,
      DisplayName: row.usuario,
      phrase_id: eventData.phrase_id,
      rating_global: eventData.rating_global,
      rating_diff: eventData.rating_diff,
      difficulty_issue: eventData.difficulty_issue,
      rating_interest: eventData.rating_interest,
      rating_duration: eventData.rating_duration,
      duration_issue: eventData.duration_issue,
      rating_hint1: eventData.rating_hint1,
      rating_hint2: eventData.rating_hint2,
      rating_hint3: eventData.rating_hint3,
      comment: eventData.comment,
      locale: eventData.locale,
      platform: eventData.platform,
      client_ver: eventData.client_ver,
    };
    if (_appendEvent(event)) {
      added++;
    }
  }
  return added;
}

function _appendEvent(event) {
  if (!event || typeof event !== "object") {
    return false;
  }
  var name = String(event.EventName || event.eventName || "");
  if (name && name.indexOf("phrase_feedback") < 0 && name.indexOf("feedback") < 0) {
    return false;
  }
  var data = event.EventData || event.eventData || event.Body || event;
  var playFabId = event.PlayFabId || event.EntityId || (event.Entity && event.Entity.Id) || data.PlayFabId || "";
  var eventId = event.EventId || event.Id || (playFabId + "|" + (event.Timestamp || "") + "|" + (data.phrase_id || ""));
  if (_alreadyImported(eventId)) {
    return false;
  }
  var usuario =
    event.DisplayName ||
    (event.PlayerProfile && event.PlayerProfile.DisplayName) ||
    data.player_name ||
    data.DisplayName ||
    "";
  _sheet().appendRow([
    event.Timestamp || event.EventTime || new Date().toISOString(),
    usuario,
    playFabId,
    data.phrase_id || "",
    data.rating_global || data.global || "",
    data.rating_diff || data.rating_difficulty || "",
    data.difficulty_issue || "",
    data.rating_interest || "",
    data.rating_duration || "",
    data.duration_issue || "",
    data.rating_hint1 || "",
    data.rating_hint2 || "",
    data.rating_hint3 || "",
    data.comment || data.comentario || "",
    data.locale || "",
    data.platform || data.plataforma || "",
    data.client_ver || data.version || "",
    eventId,
  ]);
  return true;
}

function _alreadyImported(eventId) {
  if (!eventId) {
    return false;
  }
  var sheet = _sheet();
  var last = sheet.getLastRow();
  if (last < 2) {
    return false;
  }
  var ids = sheet.getRange(2, HEADERS.length, last - 1, 1).getValues();
  for (var i = 0; i < ids.length; i++) {
    if (String(ids[i][0]) === String(eventId)) {
      return true;
    }
  }
  return false;
}

function _sheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    sheet.appendRow(HEADERS);
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function _insightsToken(tenant, clientId, clientSecret) {
  var response = UrlFetchApp.fetch("https://login.microsoftonline.com/" + tenant + "/oauth2/token", {
    method: "post",
    payload: {
      grant_type: "client_credentials",
      resource: "https://help.kusto.windows.net",
      client_id: clientId,
      client_secret: clientSecret,
    },
    muteHttpExceptions: true,
  });
  var json = JSON.parse(response.getContentText());
  if (!json.access_token) {
    throw new Error("No se pudo autenticar en Azure: " + response.getContentText().substring(0, 400));
  }
  return json.access_token;
}

function _kustoPrimaryTable(body) {
  var tables = (body && body.Tables) || (body && body.tables) || [];
  if (tables.length > 0) {
    return tables[0];
  }
  if (body && body.tables && body.tables[0]) {
    return body.tables[0];
  }
  return null;
}

function _rowByName(columns, values) {
  var row = {};
  for (var i = 0; i < columns.length; i++) {
    var col = columns[i];
    var name = col.ColumnName || col.columnName || col.Name || ("c" + i);
    row[name] = values[i];
  }
  return row;
}
