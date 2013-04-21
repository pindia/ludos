$ ->
  ws = new WebSocket('ws://localhost:8000/ws/json')
  ws.onopen = ->
    ws.send('[0, 1, 0, null, null, {}, null]')
  ws.onmessage = (evt) ->
    console.log evt.data