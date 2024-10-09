## 1.2.0

### Added

- Expose the caretaker-lib package (#107, @gpetiot)

## 1.1.1

### Changed

- show: Don't filter out 'Complete' objectives by default (#106, @gpetiot)

## 1.1.0

### Changed

- Rename field 'Quarter' to 'Iteration' according to Github dashboard (#98, @gpetiot)
- Add 'Slack Channel' field to the project export (#100, @gpetiot)
- Filter out legacy objectives by default (#103, @gpetiot)

### Added

- Enable the `--version` option (#95, @gpetiot)

## 1.0.0

### Changed

- Add missing fields (proposal link, owner, contact, JS bucket, start/end quarter, start/end dates, priority, FTE, effort) to the project csv output (#91, @gpetiot)
- Change the layout of timesheet output according to the existing spreadsheet (#81, @gpetiot)
- Add project fields (funder, team, category, objectives) to the timesheet csv output (#92, @gpetiot)
- Use Logs for warning/debug/error messages (#84, @gpetiot)

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
