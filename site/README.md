# Website

The SwiftFormat website is a small [Jekyll](https://jekyllrb.com) site whose
pages are generated from the repo's existing docs:

- `index.md` is generated from the repo's `README.md`
- `rules.md` is generated from the repo's `Rules.md`

## Local development

To start the local development server, run the following command from the repo root:

```bash
bundle exec rake site:serve
```

Once the server is running, open [http://localhost:4000](http://localhost:4000)
in your browser to preview the site. If you update `README.md` or `Rules.md`,
re-run `bundle exec rake site:prepare` to regenerate the site's pages.
