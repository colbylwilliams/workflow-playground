#!/bin/bash

DIR=$(dirname "$0")
. $DIR/_common.sh

trace() {
    echo -e "\n>>> $@ ...\n"
}

deploymentName=$(date +"%Y-%m-%d-%H%M%S%z")
deploymentOutput=""

if [ ! -z "$(find . -name '*.bicep' -print -quit)" ] ; then
    trace "Transpiling BICEP template"
    find . -name "*.bicep" -exec echo "- {}" \; -exec az bicep build --files {} \;
fi

# format the action parameters as arm parameters
deploymentParameters=$(echo "$ACTION_PARAMETERS" | jq --compact-output '{ "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#", "contentVersion": "1.0.0.0", "parameters": (to_entries | if length == 0 then {} else (map( { (.key): { "value": .value } } ) | add) end) }' )

while read p; do
    case "$p" in
        _artifactsLocation)
            deploymentParameters_adds+=( --parameters _artifactsLocation="$(dirname $CATALOG_ITEM_TEMPLATE_URL)" )
            ;;
        _artifactsLocationSasToken)
            deploymentParameters_adds+=( --parameters _artifactsLocationSasToken="?code=$CATALOG_ITEM_TEMPLATE_URL_TOKEN" )
            ;;
    esac
done < <( echo "$( cat "$CATALOG_ITEM_TEMPLATE" | jq --raw-output '.parameters | to_entries[] | select( .key | startswith("_artifactsLocation")) | .key' )" )


trace "Deploying ARM template"

if [ -z "$ENVIRONMENT_RESOURCE_GROUP_NAME" ]; then

    deploymentOutput=$(az deployment sub create --subscription $ENVIRONMENT_SUBSCRIPTION_ID \
                                                --location "$ENVIRONMENT_LOCATION" \
                                                --name "$deploymentName" \
                                                --no-prompt true --no-wait \
                                                --template-uri "$CATALOG_ITEM_TEMPLATE_URL" \
                                                --query-string code=$CATALOG_ITEM_TEMPLATE_URL_TOKEN \
                                                --parameters "$deploymentParameters" \
                                                "${deploymentParameters_adds[@]}" 2>&1)

    if [ $? -eq 0 ]; then # deployment successfully created
        while true; do

            sleep 1

            ProvisioningState=$(az deployment sub show --name "$deploymentName" --query "properties.provisioningState" -o tsv)
            ProvisioningDetails=$(az deployment operation sub list --name "$deploymentName")

            trackDeployment "$ProvisioningDetails"

            if [[ "CANCELED|FAILED|SUCCEEDED" == *"${ProvisioningState^^}"* ]]; then

                echo -e "\nDeployment $deploymentName: $ProvisioningState"

                if [[ "CANCELED|FAILED" == *"${ProvisioningState^^}"* ]]; then
                    exit 1
                else
                    break
                fi
            fi

        done
    fi

else

    deploymentOutput=$(az deployment group create --subscription $ENVIRONMENT_SUBSCRIPTION_ID \
                                                    --resource-group "$ENVIRONMENT_RESOURCE_GROUP_NAME" \
                                                    --name "$deploymentName" \
                                                    --no-prompt true --no-wait --mode Complete \
                                                    --template-uri "$CATALOG_ITEM_TEMPLATE_URL" \
                                                    --query-string code=$CATALOG_ITEM_TEMPLATE_URL_TOKEN  \
                                                    --parameters "$deploymentParameters" \
                                                    "${deploymentParameters_adds[@]}" 2>&1)

    if [ $? -eq 0 ]; then # deployment successfully created
        while true; do

            sleep 1

            ProvisioningState=$(az deployment group show --resource-group "$ENVIRONMENT_RESOURCE_GROUP_NAME" --name "$deploymentName" --query "properties.provisioningState" -o tsv)
            ProvisioningDetails=$(az deployment operation group list --resource-group "$ENVIRONMENT_RESOURCE_GROUP_NAME" --name "$deploymentName")

            trackDeployment "$ProvisioningDetails"

            if [[ "CANCELED|FAILED|SUCCEEDED" == *"${ProvisioningState^^}"* ]]; then

                echo -e "\nDeployment $deploymentName: $ProvisioningState"

                if [[ "CANCELED|FAILED" == *"${ProvisioningState^^}"* ]]; then
                    exit 1
                else
                    break
                fi
            fi

        done
    fi

fi

# trim spaces from output to avoid issues in the following (generic) error section
deploymentOutput=$(echo "$deploymentOutput" | sed -e 's/^[[:space:]]*//')

if [ ! -z "$deploymentOutput" ]; then

    if [ $(echo "$deploymentOutput" | jq empty > /dev/null 2>&1; echo $?) -eq 0 ]; then
        # the component deployment output was identified as JSON - lets extract some error information to return a more meaningful output
        deploymentOutput="$( echo $deploymentOutput | jq --raw-output '.. | .message? | select(. != null) | "Error: \(.)\n"' | sed 's/\\n/\n/g'  )"
    fi

    # our script failed to enqueue a new deployment -
    # we return a none zero exit code to inidicate this
    echo "$deploymentOutput" && exit 1

fi
