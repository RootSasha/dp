#!/bin/bash

source config.sh

# Оновлення системи та встановлення необхідних компонентів
apt update -y && apt upgrade -y
apt install -y openjdk-17-jdk curl unzip git

# Завантаження Jenkins .war файлу
JENKINS_WAR="/usr/share/jenkins/jenkins.war"
curl -o "$JENKINS_WAR" http://mirror.reverse.net/pub/apache/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# Створення директорії для Jenkins data
mkdir -p /var/lib/jenkins

# Запуск Jenkins
java -jar "$JENKINS_WAR" &

# Очікування запуску Jenkins
sleep 40

# Перевірка запуску Jenkins
if ! curl --output /dev/null --silent --head --fail "$JENKINS_URL"; then
    echo "❌ Помилка: Jenkins не запустився!"
    exit 1
fi

# Створення Groovy-скрипту для автоматичного створення адміністратора та обходу Setup Wizard
mkdir -p /var/lib/jenkins/init.groovy.d
cat <<EOF | tee /var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstanceOrNull()
if (instance == null) {
    println("❌ Помилка: неможливо отримати інстанс Jenkins")
    return
}

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("$JENKINS_USER", "$JENKINS_PASSWORD")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

# Обхід Setup Wizard
instance.installState = InstallState.INITIALIZED

instance.save()

println("✅ Адміністратор створений: $JENKINS_USER / $JENKINS_PASSWORD")
println("✅ Setup Wizard пропущено.")
EOF

# Налаштування Jenkins
bash plugin.sh
bash cred.sh
bash pipeline.sh

echo "✅ Jenkins встановлено та налаштовано!"
