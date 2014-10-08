
if [ ! -n "$AWS_ACCESS_KEY_ID" ]; then
  if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_AWS_ACCESS_KEY_ID" ]; then
    error "Please specify an AWS_ACCESS_KEY_ID"
    return 1
  else
    export AWS_ACCESS_KEY_ID="$WERCKER_AWS_CLOUDFORMATION_AWS_ACCESS_KEY_ID"
  fi
fi


if [ ! -n "$AWS_SECRET_ACCESS_KEY" ]; then
  if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_AWS_SECRET_ACCESS_KEY" ]; then
    error "Please specify an AWS_SECRET_ACCESS_KEY"
    return 1
  else
    export AWS_SECRET_ACCESS_KEY="$WERCKER_AWS_CLOUDFORMATION_AWS_SECRET_ACCESS_KEY"
  fi
fi

if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_REGION" ]; then
  error "Please specify your region."
fi

if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_STACK" ]; then
  error "Please specify your stack name."
fi


# First make sure aws is installed
if ! type aws &> /dev/null ; then
  info "awscli is not installed, trying to install through pip"
  if ! type pip &> /dev/null ; then
    fail "pip not found, make sure you have pip or awscli installed"
  else
    info "pip is available"
    debug "pip verstion is: $(pip --version)"
    pip install awscli
  fi
else
  info "awscli is available"
  debug "awscli version: $(aws --version)"
fi

if [ "$WERCKER_AWS_CLOUDFORMATION_ACTION" == "create-stack" ]; then
  echo aws --region $WERCKER_AWS_CLOUDFORMATION_REGION cloudformation create-stack \
    --stack-name "$WERCKER_AWS_CLOUDFORMATION_STACK" \
    --template-body "$WERCKER_AWS_CLOUDFORMATION_TEMPLATE_BODY" \
    --parameters $WERCKER_AWS_CLOUDFORMATION_PARAMETERS
  aws --region $WERCKER_AWS_CLOUDFORMATION_REGION cloudformation create-stack \
    --stack-name "$WERCKER_AWS_CLOUDFORMATION_STACK" \
    --template-body "$WERCKER_AWS_CLOUDFORMATION_TEMPLATE_BODY" \
    --parameters $WERCKER_AWS_CLOUDFORMATION_PARAMETERS


  STACKSTATUS="CREATE_IN_PROGRESS"

  while [ "$STACKSTATUS" == "CREATE_IN_PROGRESS" ]; do
    STACKLIST=$(aws --region $WERCKER_AWS_CLOUDFORMATION_REGION cloudformation list-stacks)
    STACKSTATUS=$(echo "$STACKLIST" | python -c 'import json,sys,os;obj=json.load(sys.stdin);ourstacks=[s["StackStatus"] for s in obj["StackSummaries"] if s["StackName"] == os.environ.get("WERCKER_AWS_CLOUDFORMATION_STACK")];print ourstacks[0]')
    echo $STACKSTATUS
    if [ "$STACKSTATUS" == "CREATE_COMPLETE" ]; then
      return 0
    elif [ "$STACKSTATUS" == "CREATE_FAILED" ]; then
      return 1
    fi
    info "Waiting for launch, checking again in 10 seconds..."
    sleep 10
  done
fi