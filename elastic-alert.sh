#!/bin/bash

ES_URL="http://192.168.19.81:9200"
ES_INDEX="dispatch-exception*/_search"
ES_USER="your-elastic-user"
ES_PASS="your-elastic-pass"

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/your-slack-webhook-code"

QUERY_PAYLOAD='{
  "_source": ["className","created","cause","method"],
  "query": {
    "range": {
      "created": {
        "gte": "now-3m",
        "lte": "now"
      }
    }
  }
}'

exception_count=$(curl -s -X GET "$ES_URL/$ES_INDEX" -H 'Content-Type: application/json' -u $ES_USER:$ES_PASS -d "$QUERY_PAYLOAD" | jq '.hits.total.value')
#declare -i exception_count
if [ "$exception_count" -gt 0 ]; then
  SLACK_MESSAGE="************************************************************************************ THE NEW EXCEPTION **************************************************************$(curl -s -X GET "$ES_URL/$ES_INDEX" -H 'Content-Type: application/json' -u $ES_USER:$ES_PASS -d '{
    "_source": ["className","created","cause","method"],
    "size": 40,
    "query": {
      "range": {
        "created": {
          "gte": "now-3m",
          "lte": "now"
        }
      }
    }
  }' | jq -c '.hits.hits[] | {className: ._source.className, created: ._source.created, cause: ._source.cause, method: ._source.method}'| jq )"

  SLACK_PAYLOAD=$(jq -n --arg text "$SLACK_MESSAGE" '{"text": $text}')

  curl -s -X POST -H 'Content-type: application/json' --data "$SLACK_PAYLOAD" "$SLACK_WEBHOOK_URL"
fi
