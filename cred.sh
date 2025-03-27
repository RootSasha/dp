#!/bin/bash

source config.sh

# Генерація або використання SSH-ключа
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Генеруємо новий SSH-ключ..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "$GITHUB_EMAIL" -N "" -q
    echo "✅ Новий SSH-ключ створено!"
else
    echo "SSH-ключ вже існує, використовуємо його."
fi

# Додавання SSH-ключа до Jenkins
SSH_PRIVATE_KEY=$(cat "$SSH_KEY_PATH")
SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH.pub")

cat <<EOF | tee /var/lib/jenkins/init.groovy.d/add-credentials.groovy > /dev/null
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

println("[INIT] Починаємо додавання SSH credentials...")

def instance = Jenkins.instance
if (instance == null) {
    println("❌ Помилка: неможливо отримати інстанс Jenkins")
    return
}

def credentialsStore = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

# Додавання SSH-ключа
def sshKey = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    "$CREDENTIAL_ID",
    "jenkins",
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource("""$SSH_PRIVATE_KEY"""),
    "",
    "Автоматично створені Global SSH credentials"
)
credentialsStore.addCredentials(Domain.global(), sshKey)

instance.save()

println("✅ Global SSH credentials '$CREDENTIAL_ID' додано успішно!")
EOF

echo "✅ Groovy-скрипт для додавання SSH-ключа створено!"

# Налаштування SSH для Jenkins
mkdir -p /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
chown -R jenkins:jenkins /var/lib/jenkins/.ssh

echo "Додаємо GitHub до known_hosts..."
ssh-keyscan -H github.com | tee /var/lib/jenkins/.ssh/known_hosts > /dev/null
chmod 600 /var/lib/jenkins/.ssh/known_hosts
chown jenkins:jenkins /var/lib/jenkins/.ssh/known_hosts

echo "✅ SSH налаштовано для Jenkins!"
