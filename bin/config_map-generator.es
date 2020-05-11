Query

DELETE polycube
DELETE apache

PUT polycube
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

GET polycube
