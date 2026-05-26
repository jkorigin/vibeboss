# Secrets

Store credentials and sensitive values here. This directory is gitignored.

**Rules:**
- Never echo secret values in conversational output
- Always reference by path: `hq/secrets/<name>`
- Never commit secrets — verify `.gitignore` before any `git add`

**Format:** plain text files, one secret per file. Name files descriptively: `whatsapp-api-key`, `openai-key`, etc.
