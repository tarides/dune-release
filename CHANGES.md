## unreleased

### Changed

- Change the layout of timesheet output according to the existing spreadsheet (#81, @gpetiot)

## 0.3.0

- Fix incomplete queries when we retry with a smaller number of items per page.
  Follow up of #65. (#89, @samoht)
- Fix floating point number precision when printing days in CSV files.
  (#89, @samoht)

## 0.2.0

- Use anonymous data in cram tests (#86, @samoht)
- Use a dynamic number of entries per page for GraphQL calls. On errors,
  retry with a smaller number of entries (#85, @samoht)

## 0.1.0

### Changed

- Sort timesheet output (#80, @gpetiot)
- Add more debug information to debug rate-limiting errors (#75, @samoht)
- Depend on okra-lib.3.0.0 (#56, #65, #68, #82, @gpetiot)

### Fixed

- Fetch: fix the source for timesheets when okr-update-dir or admin-dir is specified (#69 , @gpetiot)

(changes before May '24 not tracked)
