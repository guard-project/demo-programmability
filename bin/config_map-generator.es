Query

DELETE ssh-server
DELETE apache

PUT ssh-server
{
  "mappings": {
    "doc": {
      "properties": {
          "LastUpdate": {
              "type": "date"
          }
      }
    }
  }
}

GET ssh-server
