# Allow setTimeout and setInterval to be called with either argument order

_realSetTimeout = setTimeout
this.setTimeout = (a, b) ->
  if typeof a is "number"
    _realSetTimeout b, a
  else
    _realSetTimeout a, b

_realSetInterval = setInterval
this.setInterval = (a, b) ->
  if typeof a is "number"
    _realSetInterval b, a
  else
    _realSetInterval a, b