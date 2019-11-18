let gh_v3_api_DR_example =
  {|
{
  "url":"https://api.github.com/repos/NathanReb/dune-release-testing/releases/assets/12789323",
  "id":12789323,
  "node_id":"MDEyOlJlbGVhc2VBc3NldDEyNzg5MzIz",
  "name":"dummy-v0.0.0.tbz",
  "label":"",
  "uploader":{
    "login":"NathanReb",
    "id":7419360,
    "node_id":"MDQ6VXNlcjc0MTkzNjA=",
    "avatar_url":"https://avatars2.githubusercontent.com/u/7419360?v=4",
    "gravatar_id":"",
    "url":"https://api.github.com/users/NathanReb",
    "html_url":"https://github.com/NathanReb",
    "followers_url":"https://api.github.com/users/NathanReb/followers",
    "following_url":"https://api.github.com/users/NathanReb/following{/other_user}",
    "gists_url":"https://api.github.com/users/NathanReb/gists{/gist_id}",
    "starred_url":"https://api.github.com/users/NathanReb/starred{/owner}{/repo}",
    "subscriptions_url":"https://api.github.com/users/NathanReb/subscriptions",
    "organizations_url":"https://api.github.com/users/NathanReb/orgs",
    "repos_url":"https://api.github.com/users/NathanReb/repos",
    "events_url":"https://api.github.com/users/NathanReb/events{/privacy}",
    "received_events_url":"https://api.github.com/users/NathanReb/received_events",
    "type":"User",
    "site_admin":false},
  "content_type":"application/x-tar",
  "state":"uploaded",
  "size":811,
  "download_count":0,
  "created_at":"2019-05-21T09:27:22Z",
  "updated_at":"2019-05-21T09:27:22Z",
  "browser_download_url":"https://github.com/NathanReb/dune-release-testing/releases/download/v0.0.0/dummy-v0.0.0.tbz"
}
|}

let gh_v3_api_example =
  {|
{
  "url": "https://api.github.com/repos/octocat/Hello-World/releases/assets/1",
  "browser_download_url": "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip",
  "id": 1,
  "node_id": "MDEyOlJlbGVhc2VBc3NldDE=",
  "name": "example.zip",
  "label": "short description",
  "state": "uploaded",
  "content_type": "application/zip",
  "size": 1024,
  "download_count": 42,
  "created_at": "2013-02-27T19:35:32Z",
  "updated_at": "2013-02-27T19:35:32Z",
  "uploader": {
    "login": "octocat",
    "id": 1,
    "node_id": "MDQ6VXNlcjE=",
    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
    "gravatar_id": "",
    "url": "https://api.github.com/users/octocat",
    "html_url": "https://github.com/octocat",
    "followers_url": "https://api.github.com/users/octocat/followers",
    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
    "organizations_url": "https://api.github.com/users/octocat/orgs",
    "repos_url": "https://api.github.com/users/octocat/repos",
    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
    "received_events_url": "https://api.github.com/users/octocat/received_events",
    "type": "User",
    "site_admin": false
  }
}
|}
