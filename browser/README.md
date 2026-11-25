# Browser rules

CSS and filters that fix sites I use in Chrome. Two extensions apply them:

- **uBlock Origin Lite (uBOL)** hides things. Its rules beat a site's own
  `!important` styles. It reads `ubol/personal.txt` from GitHub.
- **Stylebot** restyles sites. Each file in `stylebot/` is one site's CSS,
  named after the site (`github.com.css`). `browser-rules push` copies them
  into Stylebot.

Chrome sync reinstalls both extensions on a new Mac but not their rules, so
the rules live here.

## One-time setup on each Mac

1. On `chrome://extensions`, open uBOL's **Details**:
   - Set **Site access** to "On all sites".
   - Turn on **Allow User Scripts**. Do this before adding any list: lists added
     before it is on stop working until you remove and re-add them.
2. In uBOL's dashboard:
   - **Filter lists**: turn on all seven Annoyances lists.
   - **Filter lists → Add filter list**: add each URL that `browser-rules urls`
     prints (this repo's list and yt-neuter for YouTube).
   - **Settings**: set the default filtering mode to **Complete**. Turn it
     down for any site that breaks.
3. Set up Stylebot:
   - In Stylebot's settings, turn on **Allow command line access** and, to
     share styles between Macs, Google Drive sync.
   - Run `stylebot install` once (the CLI comes from mise), then
     `browser-rules push`.

## Day to day

- **Hide something:** add a line to `ubol/personal.txt`, run
  `browser-rules lint`, then commit and push to `main`. uBOL picks the change
  up within a day. To get it sooner, wait about 5 minutes for GitHub's cache,
  then turn the list off and on in uBOL.
- **Restyle a site:** edit or add `stylebot/<site>.css`, then run
  `browser-rules diff` and `browser-rules push`.
- **Changed a style in Stylebot's editor:** run `browser-rules pull` to copy it
  back here.

Every uBOL rule must start with a hostname (`amazon.com##.selector`). uBOL drops
rules that don't, and `browser-rules lint` catches them.

This repo is public, so keep intranet, client and other private hostnames out
of these files. Put those rules in uBOL's **Custom filters** pane instead.
