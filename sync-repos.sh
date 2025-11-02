#!/bin/bash
echo "🔄 Syncing to both repositories..."

# Push to GitHub (primary)
git push github main
echo "✅ Pushed to GitHub"

# Push to Azure DevOps (triggers pipeline)
git push origin main  
echo "✅ Pushed to Azure DevOps"

echo "🚀 Both repositories updated!"