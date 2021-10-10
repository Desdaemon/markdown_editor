<template>
  <ion-page>
    <ion-header :translucent="true">
      <ion-toolbar>
        <ion-title>Blank</ion-title>
      </ion-toolbar>
    </ion-header>
    <template></template>
    <ion-content :fullscreen="true">
      <ion-grid>
        <ion-row>
          <ion-col size="6">
            <textarea
              name="editor"
              id="editor"
              :value="source"
              @input="onInput"
              @scroll="onScroll"
            ></textarea>
          </ion-col>
          <ion-col size="6" id="preview" class="markdown-body">
            <div class="d-flex justify-content-center">
              <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
              </div>
            </div>
          </ion-col>
        </ion-row>
        <ion-row class="row row-cols-auto justify-content-between">
          <ion-col id="toolbar" class="col">
            <span class="material-icons">call_end</span>
            <span class="material-icons">format_bold</span>
            <span class="material-icons">format_italic</span>
            <span class="material-icons">format_strikethrough</span>
            <span class="material-icons">functions</span>
            <span class="material-icons">format_indent_increase</span>
            <span class="material-icons">format_indent_decrease</span>
            <span>Spaces: {{ indentCount }}</span>
          </ion-col>
          <span class="material-icons col">menu</span>
        </ion-row>
      </ion-grid>
    </ion-content>
  </ion-page>
</template>

<script lang="ts">
import {
  IonContent,
  IonHeader,
  IonGrid,
  IonRow,
  IonCol
  /* IonPage, */
  /* IonTitle, */
  /* IonToolbar */
} from "@ionic/vue";
import { defineComponent } from "vue";

export default defineComponent({
  name: "Home",
  components: {
    IonContent,
    IonHeader,
    IonGrid,
    IonRow,
    IonCol
  },
  data() {
    return {
      source: ""
    };
  }
});
</script>

<style scoped>
:root {
  --bottom-bar-height: 35px;
  --row-height: calc(100vh - var(--bottom-bar-height));
}
body {
  display: grid;
}
#toolbar {
  overflow: auto;
  white-space: nowrap;
  user-select: none;
  height: var(--bottom-bar-height);
}
#editor {
  outline: none;
  resize: none;
  border: none;
  height: var(--row-height);
  font-family: "JetBrainsMono Nerd Font", "Courier New", Courier, monospace;
}
#preview {
  height: var(--row-height);
  overflow: scroll;
}
</style>
