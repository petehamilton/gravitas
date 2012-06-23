TEST_USER = 'niklas'
TEST_PASSWORD = 'niklas'
TEST_DISPLAY_NAME = 'Niklas'

RESPONSE_TIMEOUT_MS = 50  # Timeout in ms we expect a websocked roundtrip to be done in

casper = require('casper').create
  clientScripts:  []
  # verbose: true
  # logLevel: "debug"

{ dump } = utils = require 'utils'

# Takes a screenshots and saves it into screenshot directory.
screenshot = (name) -> casper.capture "gen/screenshots/#{name}.png"

# Returns the text contained by elements matching `selector`.
evalText = (selector) ->
  casper.evaluate ((selector) -> $(selector).text()), selector: selector

# Asserts that the elements of given selector are visible.
assertVisible = (selector, msg) ->
  visible = casper.evaluate ((selector) -> $(selector).is ':visible'), selector: selector
  casper.test.assert visible, msg

# Asserts that the expression extracted from the page by `testValueFn` is equal `expected`.
assertEvalEqual = (testValueFn, expected, msg, replacements) ->
  testValue = casper.evaluate testValueFn, replacements
  casper.test.assertEquals testValue, expected, msg

# Assert that the (trimmed) text of the elements matching `selector` equals `expected`.
assertEvalSelectorTextEqual = (selector, expected, msg) ->
  assertEvalEqual ((selector) -> $.trim($(selector).text())), expected, msg, selector: selector

# Fills in the form matching `selector` and optionally submits it with jQuery's `.submit()`.
fillJquery = (selector, vals, submit) ->
  casper.fill selector, vals, false
  if submit == true
    casper.evaluate ((selector) -> $(selector).submit()), selector: selector


casper.start "http://localhost:8000/", ->
  @test.info "Page load"

  @test.assertExists '#app', 'application is served'

  screenshot 'page_load'


casper.then ->
  @test.info "Login"

  @waitUntilVisible '#login-form', ->

    screenshot 'login_form'

    # TODO check why submitting from with true doesn't work
    @fill '#login-form', { userName: TEST_USER, password: TEST_PASSWORD }, false

    screenshot 'login_form_filled'

    @click '#login-window input[type=submit]'

    @waitWhileVisible '#login-form', =>
      screenshot 'after_login'
      @test.pass 'Login form disappeared'

      assertVisible '#menu .playbutton', 'Play button is visible'
      assertEvalSelectorTextEqual '#menu .playbutton', 'Play', 'Play button text is right'
      assertEvalSelectorTextEqual '#username-span', TEST_USER, 'Player name is set'

      @wait 1000, =>
        screenshot 'after_login_time'


casper.then ->
  @test.info "Menu"

  @click '#navigation [data-menu=achievements]'
  @test.assertTextExists 'Achievements', 'achievements page exists'
  screenshot 'achievements'

  @click '#navigation [data-menu=settings]'
  @test.assertTextExists 'Profile Picture', 'settings page has profile picture section'
  @test.assertTextExists 'Change Password', 'settings page has change password section'
  screenshot 'settings'

  @click '#navigation [data-menu=search]'
  screenshot 'search'
  fillJquery '#search-form', { user: 'lukasz' }, true
  screenshot 'search_filled'
  @waitUntilVisible '.search-result', ->
    screenshot 'search_result'
    assertVisible '.search-profile-picture', 'profile picture is shown'

  rating = evalText '#lobby-window .rating'
  @test.assert (500 <= rating <= 2200), 'user rating is valid'


casper.then ->
  @test.info "Lobby"

  @click '#lobby-window .playbutton'
  @waitUntilVisible '#assembly-window', ->
    screenshot 'lobby'
    assertVisible '.waiting-label', 'waiting label is visible'
    assertVisible '.lobby-chat-container', 'chat is visible'
    assertEvalSelectorTextEqual '.assembly-content label.player:first', TEST_USER, 'player name appears in waiting list'

    @test.comment "Chat"
    fillJquery '.lobby-chat-form', { text: 'Message 1' }, true
    @wait RESPONSE_TIMEOUT_MS, ->
      assertEvalSelectorTextEqual '.lobby-chat p:first', "#{TEST_DISPLAY_NAME}: Message 1", 'chat works'
      screenshot 'chat_result'

      @test.comment "Leave"
      @click '#assembly-window .leavebutton'
      @waitWhileVisible '#assembly-window', ->
        assertVisible '#search-form', 'back in the menu where in we were before on clicking Leave'


# Run
casper.run -> @test.renderResults true
