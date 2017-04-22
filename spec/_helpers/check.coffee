module.exports = (focusOnCheck, verb) ->

  check: (itName, itBody) ->

    (if focusOnCheck == itName then fit else it) itName,

    if not verb
      itBody
    else if itBody.length > 0
      (done) ->
        console.info "check: #{itName}"
        itBody.call @, done
        return
    else
      ->
        console.info "check: #{itName}"
        itBody.call @
        return

    return

  xcheck: (itName, itBody) -> return
