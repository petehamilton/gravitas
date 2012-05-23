# Observable taking conversion function
ko.extenders.convert = (target, convert_fn) ->
  result = ko.computed
    read: target
    write: (newValue) ->
      target(convert_fn newValue)

  result(target())
  result
