<template>
  <div id="flexview" class="background-container">
    <div class="content">
      <div class="flexColumn">
        <div class="leftPanelTopSpace">
          <transition name="smooth-display">
            <div v-if="isMinimizedButtonsVisible" class="minimizedButtonsPanel leftPanelTopMinimizedButtonsPanel"
              v-bind:class="{
                minimizedButtonsPanelRightElements: isWindowHasFrame,
              }">
              <button v-on:click="onAccountSettings()" title="Account settings">
                <img src="@/assets/user.svg" />
              </button>

              <button v-on:click="onSettings()" title="Settings">
                <img src="@/assets/settings.svg" />
              </button>

              <button v-on:click="onMaximize(true)" title="Show map">
                <img src="@/assets/maximize.svg" />
              </button>
            </div>
          </transition>
        </div>
        <div class="flexColumn" style="min-height: 0px">
          <transition name="fade" mode="out-in">
            <component v-bind:is="currentViewComponent" :onConnectionSettings="onConnectionSettings"
              :onWifiSettings="onWifiSettings" :onFirewallSettings="onFirewallSettings"
              :onAntiTrackerSettings="onAntitrackerSettings" :onDefaultView="onDefaultLeftView" id="left"></component>
          </transition>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
const sender = window.ipcSender;

import { DaemonConnectionType } from "@/store/types";
import { IsWindowHasFrame } from "@/platform/platform";
import Init from "@/components/Component-Init.vue";
import Login from "@/components/Component-Login.vue";
import Control from "@/components/Component-Control.vue";
import ParanoidModePassword from "@/components/ParanoidModePassword.vue";

export default {
  components: {
    Init,
    Login,
    Control,
    ParanoidModePassword,
  },
  data: function () {
    return {
      isCanShowMinimizedButtons: true,
    };
  },
  computed: {
    isWindowHasFrame: function () {
      return IsWindowHasFrame();
    },
    isLoggedIn: function () {
      return this.$store.getters["account/isLoggedIn"];
    },
    currentViewComponent: function () {
      const daemonConnection = this.$store.state.daemonConnectionState;
      if (
        daemonConnection == null ||
        daemonConnection === DaemonConnectionType.NotConnected ||
        daemonConnection === DaemonConnectionType.Connecting
      )
        return Init;
      if (this.$store.state.uiState.isParanoidModePasswordView === true)
        return ParanoidModePassword;
      if (!this.isLoggedIn) return Login;

      return Control;
    },
    isMapBlured: function () {
      if (this.currentViewComponent !== Control) return "true";
      return "false";
    },
    isMinimizedButtonsVisible: function () {
      if (this.currentViewComponent !== Control) return false;
      if (this.isCanShowMinimizedButtons !== true) return false;
      return this.isMinimizedUI;
    },
    isMinimizedUI: function () {
      return this.$store.state.settings.minimizedUI;
    },
  },

  methods: {
    onAccountSettings: function () {
      //if (this.$store.state.settings.minimizedUI)
      sender.ShowAccountSettings();
      //else this.$router.push({ name: "settings", params: { view: "account" } });
    },
    onSettings: function () {
      sender.ShowSettings();
    },
    onConnectionSettings: function () {
      sender.ShowConnectionSettings();
    },
    onWifiSettings: function () {
      sender.ShowWifiSettings();
    },
    onFirewallSettings: function () {
      sender.ShowFirewallSettings();
    },
    onAntitrackerSettings: function () {
      sender.ShowAntitrackerSettings();
    },
    onDefaultLeftView: function (isDefaultView) {
      this.isCanShowMinimizedButtons = isDefaultView;
    },
    onMaximize: function (isMaximize) {
      this.$store.dispatch("settings/minimizedUI", !isMaximize);
    },
  },
};
</script>

<style scoped lang="scss">
@import "@/components/scss/constants";

.background-container {
  position: relative;
  height: 100vh
}

.background-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('@/assets/background.webp') no-repeat center center;
  background-size: cover;
  opacity: 0.28;
  z-index: -1;
}

.content {
  z-index: 1;
  padding: 20px;
}

#flexview {
  position: relative;
  display: flex;
  flex-direction: row;
  height: 100%;
}

#left {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 320px;
}

div.minimizedButtonsPanelRightElements {
  display: flex;
  justify-content: flex-end;
}

div.minimizedButtonsPanel {
  display: flex;

  margin-left: 10px;
  margin-right: 10px;
  margin-top: 10px;
}

div.minimizedButtonsPanel button {
  @extend .noBordersBtn;

  -webkit-app-region: no-drag;
  z-index: 101;
  cursor: pointer;

  padding: 0px;
  margin-left: 6px;
  margin-right: 6px;
}

div.minimizedButtonsPanel img {
  height: 18px;
}
</style>
