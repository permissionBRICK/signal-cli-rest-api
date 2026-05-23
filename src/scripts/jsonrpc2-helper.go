package main

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"strings"

	"github.com/bbernhard/signal-cli-rest-api/utils"
	log "github.com/sirupsen/logrus"
)

const supervisorctlConfigTemplate = `
[program:%s]
process_name=%s
command=%s --output=json --config %s%s daemon %s%s%s%s --tcp 127.0.0.1:%d%s
autostart=true
autorestart=true
startretries=10
user=signal-api
directory=/usr/bin/
redirect_stderr=true
stdout_logfile=/var/log/%s/out.log
stderr_logfile=/var/log/%s/err.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
numprocs=1
`

func main() {
	signalCliConfigDir := "/home/.local/share/signal-cli/"
	signalCliConfigDirEnv := utils.GetEnv("SIGNAL_CLI_CONFIG_DIR", "")
	if signalCliConfigDirEnv != "" {
		signalCliConfigDir = signalCliConfigDirEnv
		if !strings.HasSuffix(signalCliConfigDirEnv, "/") {
			signalCliConfigDir += "/"
		}
	}

	jsonRpc2ClientConfig := utils.NewJsonRpc2ClientConfig()

	var tcpPort int64 = 6001

	jsonRpc2ClientConfig.AddEntry(utils.MULTI_ACCOUNT_NUMBER, utils.JsonRpc2ClientConfigEntry{TcpPort: tcpPort})

	signalCliBinary := "signal-cli"
	signalMode := utils.GetEnv("MODE", "json-rpc")
	if signalMode == "json-rpc-native" {
		signalCliBinary = "signal-cli-native"
	} else if signalMode != "json-rpc" {
		log.Fatal("The mode needs to be either 'json-rpc' or 'json-rpc-native'")
	}

	signalCliIgnoreAttachments := ""
	ignoreAttachments := utils.GetEnv("JSON_RPC_IGNORE_ATTACHMENTS", "")
	if ignoreAttachments == "true" {
		signalCliIgnoreAttachments = " --ignore-attachments"
	}

	signalCliIgnoreStories := ""
	ignoreStories := utils.GetEnv("JSON_RPC_IGNORE_STORIES", "")
	if ignoreStories == "true" {
		signalCliIgnoreStories = " --ignore-stories"
	}

	signalCliIgnoreAvatars := ""
	ignoreAvatars := utils.GetEnv("JSON_RPC_IGNORE_AVATARS", "")
	if ignoreAvatars == "true" {
		signalCliIgnoreAvatars = " --ignore-avatars"
	}

	signalCliIgnoreStickers := ""
	ignoreStickers := utils.GetEnv("JSON_RPC_IGNORE_STICKERS", "")
	if ignoreStickers == "true" {
		signalCliIgnoreStickers = " --ignore-stickers"
	}

	supervisorctlProgramName := "signal-cli-json-rpc-1"
	supervisorctlLogFolder := "/var/log/" + supervisorctlProgramName
	_, err := exec.Command("mkdir", "-p", supervisorctlLogFolder).Output()
	if err != nil {
		log.Fatal("Couldn't create log folder ", supervisorctlLogFolder, ": ", err.Error())
	}

	trustNewIdentities := ""
	trustNewIdentitiesEnv := utils.GetEnv("JSON_RPC_TRUST_NEW_IDENTITIES", "")
	if trustNewIdentitiesEnv == "on-first-use" {
		trustNewIdentities = " --trust-new-identities on-first-use"
	} else if trustNewIdentitiesEnv == "always" {
		trustNewIdentities = " --trust-new-identities always"
	} else if trustNewIdentitiesEnv == "never" {
		trustNewIdentities = " --trust-new-identities never"
	} else if trustNewIdentitiesEnv != "" {
		log.Fatal("Invalid JSON_RPC_TRUST_NEW_IDENTITIES environment variable set!")
	}

	// Optionally expose the signal-cli daemon's HTTP JSON-RPC listener
	// directly to the outside world. This is the transport that signal-cli
	// clients like Hermes expect (POST'ing JSON-RPC bodies to /). The local
	// --tcp socket is kept unchanged so the REST API code path is untouched.
	signalCliHttpListener := ""
	httpPortEnv := utils.GetEnv("JSON_RPC_HTTP_PORT", "")
	if httpPortEnv != "" {
		httpBind := utils.GetEnv("JSON_RPC_HTTP_BIND", "0.0.0.0")
		signalCliHttpListener = " --http " + httpBind + ":" + httpPortEnv
		log.Info("Adding HTTP JSON-RPC listener on ", httpBind, ":", httpPortEnv)
	}

	log.Info("Updated jsonrpc2.yml")

	//write supervisorctl config
	supervisorctlConfigFilename := "/etc/supervisor/conf.d/" + "signal-cli-json-rpc-1.conf"

	supervisorctlConfig := fmt.Sprintf(supervisorctlConfigTemplate, supervisorctlProgramName, supervisorctlProgramName, signalCliBinary,
		signalCliConfigDir, trustNewIdentities, signalCliIgnoreAttachments, signalCliIgnoreStories,
		signalCliIgnoreAvatars, signalCliIgnoreStickers, tcpPort, signalCliHttpListener,
		supervisorctlProgramName, supervisorctlProgramName)

	err = ioutil.WriteFile(supervisorctlConfigFilename, []byte(supervisorctlConfig), 0644)
	if err != nil {
		log.Fatal("Couldn't write ", supervisorctlConfigFilename, ": ", err.Error())
	}

	// write jsonrpc.yml config file
	err = jsonRpc2ClientConfig.Persist(signalCliConfigDir + "jsonrpc2.yml")
	if err != nil {
		log.Fatal("Couldn't persist jsonrpc2.yaml: ", err.Error())
	}
}
