# Nova Amazon Bedrock Provider

Official Nova provider plugin for Amazon Bedrock. It adds Bedrock model discovery, text generation, embeddings, and guardrail-aware provider routing for agents that use AWS-hosted models.

Install from Nova:

```bash
nova plugin add @nova/amazon-bedrock-provider
```

Configure AWS credentials and region through your normal Nova credential/profile setup, then select Bedrock models with the `amazon-bedrock/...` provider prefix.
