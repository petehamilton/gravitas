# Observable taking conversion function
ko.extenders.convert = (target, convert_fn) ->
  result = ko.computed
    read: target
    write: (newValue) ->
      target(convert_fn newValue)

  result(target())
  result


# Requires jQuery
ko.bindingHandlers.fadeVisible =
  init: (element, valueAccessor) ->
    value = valueAccessor()
    $(element).toggle ko.utils.unwrapObservable(value)

  update: (element, valueAccessor) ->
    value = valueAccessor()
    (if ko.utils.unwrapObservable(value) then $(element).fadeIn() else $(element).fadeOut())


# Subscribes the given cookie to "true"/unset on change of `observable`.
# subscribeCookie = (observable, cookieName, callback) ->
#   observable.subscribe (val) ->
#     $.cookie cookieName, (if val then "true" else null)
#     callback val

# cookieObservable = (initialValue, cookieName, callback) ->
#   observable = ko.observable initialValue

#   observable.subscribe (val) ->
#     $.cookie cookieName, (if val then "true" else null)
#     callback val

#   observable


ko.extenders.cookie = (target, cookieKey) ->

  result = ko.computed
    read: target
    write: (newValue) ->
      log "write #{cookieKey}, #{JSON.stringify(newValue)}"
      $.cookie cookieKey, JSON.stringify(newValue)
      target newValue

  result(target())
  result

@makeCookieObservable = (cookieKey) ->
  ko.observable(JSON.parse($.cookie cookieKey)).extend { cookie: cookieKey }
