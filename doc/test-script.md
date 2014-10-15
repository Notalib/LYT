Test schedule for LYT

Supported platforms:
    - Windows:

      - Internet explorer:

        - IE9

        - IE10

        - IE11 on Windows 7

        - IE11 on Windows 8

      - Google Chrome

        - Latest

    - MacOS X:

      - Google Chrome

      - Safari

    - Android:

      - Android Browser

      - Google Chrome

    - iPad and iPhone:

      - Safari

Login:

    - 1: Log on using correct username + password

    - 2: Log on using correct username + incorrect password

    - 3: Log on using incorrect username + correct password

    - 4: Log on correctly, close tab, open it again. Check, that you are still logged in.

    - 5: Log on another device, then log off. Check, that you are still logged on in first session

    - 6: Log on correctly, log off, close tab, return to page. Check, that you are logged off.

    - 7: Log on using the guest link, check that you can play the books on the
      shelf, use the search engine, but only play the freely available books in
      the database.

    - 8: Log on as guest, log off, then log on as normal user. Check your profile:
      are you registered as the right user?

    - 9: Log on a normal user, then log off and log on as another normal user. Check your profile:
      are you registered as the right user?


Searching and adding books:

    - 1: Write 'Harry Potter' in the search field. Find all available Potter books?
         (The available HP books are the following:
         Harry Potter and the Chamber of Secrets,
         Harry Potter and the Prisoner of Azkaban,
         Harry Potter and the Goblet of Fire,
         Harry Potter and the Order of the Phoenix,
         Harry Potter and the Half-Blood Prince,
         Harry Potter and the Deathly Hallows)

    - 2: Write 'krimi' in the search field. Check, that you only get crime fiction - i.e.
         that you don't get any academic books on crime or similar.

    - 3: Write 'krimi Larsson' in the search field. Check, that you only get crime
      fiction involving the name Larsson.

    - 4: Find a book (type doesn't matter) and add it.

    - 5: Log out, close tab, open again and log in. Are all your books still there?

    - 6: Remove a book, repeat above. Is the removal registered on return?

    - 7: Do a search, click one of the books and then click the browser's back
      button. Does it display the last search result? Repeat using the applications
      back to search results - button.


Playing books (linearly):

    General:

        - 1: Open the book, press 'Play'. Does the book begin playing?

        - 2: Whilst playing, does the book start each new segment automatically?

        - 3: Whilst playing, click 'Pause', then resume playing.


    (On a smartphone):

        - 4: Make a call to the phone whilst playing the book. Check, that
          the book stops the playing, and can be started again at the correct
          chapter after the call

        - 5: Whilst playing, let the phone go on standby and lock. Does the
          book keep playing undisturbed?


Navigation between book sections:

    - 1: Whilst playing a book, open the Chapter view, click a new chapter. Does it
      begin playing?

    - 2: Stop playing, repeat above. Does the new chapter begin playing immediately?

    - 3: Whilst playing, click on the chapter's timeline. Does it jump to the place
      you've clicked?

    - 4: Stop playing, repeat above. Does it begin the correct place when pressing
      'Play'?

    - 5: In the middle of a chapter, click 'Forward'. Does it skip to the following
      section?

    - 6: In the middle of a chapter, click 'Forward' twice. Does it skip two sections
      ahead?

    - 7: In the middle of a chapter, click 'Forward' ten times in rapid succession.
      Does it skip ten sections ahead?

    - 8: Wait until just before the ending of a section (not a book chapter), then
      click 'Forward'. Do you skip to the next section?

    - 9: Wait until just before the ending of a book chapter, then click 'Forward'.
      Does it skip to the beginning of the new chapter?

    - 10: Repeat above with the 'Backwards' button.

    - 11: Just at the beginning of a new section (not a book chapter), click 'Backwards'.
      Does it begin at the beginning of the last section?

    - 12: Just at the beginning of a new book chapter, click 'Backwards'. Does it begin
      at the last section of the previous chapter?


Special cases for playing:

    - Whilst on a mobile device: Open a book, pause it. Then exit the player,
      log on another network and return to the book again. Does it continue uninterrupted?


Modifying settings:

    - 1: Log on as normal user, change background colour. Play a book, checking that
      the changes are registered.

    - 2: Repeat above consecutively with read speed (where available), text size and font.

    - 3: Log off, reload, log on again and check that changes persist.

    - 4: Log on as a guest, change background colour, text size, and font, play a book.

    - 5: Log out, log on as guest again and check that the changes are not registered.

    - Log on a previous version of the code (i.e. the live version), change some of your
      settings and log out. Log on the current test release and check, that the changes from
      the old version appear in the new.


Comics (THIS TEST CASE NEEDS REVIEWING):

        - NOTE: The player must be running the cartoon player, which works by zooming in at the specific text being read

        - 1: Test the first three cases of "Playing books (linearly)" on the comic.

        - 2: Whilst Playing, Check that the image automatically follows the text being read.

        - 3: Whilst playing, click on the chapter's timeline. Does it jump to the place you've clicked?

        - 4: Check, that clicking repeatedly on the images does not affect playing.

        - 5: Forward and backward playing, checking that this does not disrupt the showing of the images.

    (On a smartphone/Tablet)

        - 1: Run the same test listed above.

        - 2: Test the two cases for smartphone of "Playing books (linearly)".

        - 3: Whilst playing, check that the image is scaled properly. Can you see everything?

Bookmarks:

        - 1: Open a book, place a bookmark in three different chapters.

        - 2: Enter the bookmark index, click consecutively on each of the
             bookmarks. Do they take you to the correct place in the book?

        - 3: Whilst playing, doubleclick the bookmark button. Check the
             bookmark index: make sure that there is only one bookmark.

        - 4: Wait until just before the end of a sound segment, then place a
             bookmark there. Does it work correctly?

        - 5: Place a bookmark just at the beginning of a sound segment. Does it work
             correctly?

        - 6: Log out, then back in. Are your bookmarks still there?

        - 7: Remove a book mark, log out and back in. Is it gone?

        - Log on an older version of the code base (e.g. the live version), add a
          few bookmarks and log out again. Log on the test version and check that the
          bookmarks from the old version appear on the new. NB: This doesn't/isn't
          supposed to work the other way around.

Sharing bookmarks:

        - 1: Open a book, place a bookmark in the middle of a segment.

        - 2: Change to another chapter in the book and wait for it to start
          playing.

        - 3: Open the bookmarks and note down the link on the bookmark that
          was created. Click the bookmark and verify that it starts playing at
          the right place in the book.

        - 4: Open the bookmarks and choose to share the bookmark. Verify that
          the link is identical to the one noted down above. Click the share
          button and verify in the email that the link displayed is still
          correct and the wording looks right.

Shortcuts (test only on PCs):

        - 1: Open a book. Verify the following shortcuts:

          - Play/pause: alt + ctrl + space

          - Next segment: alt + arrow right

          - Previous segment: alt + arrow left

          - Help: alt + ctrl + h

          - Place bookmark: alt + ctrl + m

