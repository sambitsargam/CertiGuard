<template>
  <div class="main">
    <div class="title">Verifier</div>
    <div v-if="allowScan" class="qr-container">
      <QrcodeStream @detect="onDecode">
      </QrcodeStream>
    </div>
    <div v-else>
      <CButton color="primary" @click="scan">Scan QR Code on Certificate</CButton>
    </div>
    <div v-if="verifyStatus !== ''"  style="width: 300px">
      <Vue3Lottie
        :animationData="verifyStatus === 'YES' ? yesAnimation : noAnimation"
        :loop="false"
      />
    </div>
  </div>
</template>

<script>
import { QrcodeStream } from 'vue-qrcode-reader'
import { CButton, CSpinner } from '@coreui/vue';

import YESAnimation from '../assets/yes.svg'
import NOAnimation from '../assets/no.json'


export default {
  name: 'Verifier',
  components: { QrcodeStream, CButton },
  props: {
    webService: String,
  },
  data() {
    return {
      allowScan: false,
      verifyStatus: "",
      yesAnimation: YESAnimation,
      noAnimation: NOAnimation
    }
  },
  methods: {
    scan() {
      this.allowScan = true;
      this.verifyStatus = "";
    },
    async onDecode(data) {
      try {
        if (data !== "") {
          this.allowScan = false;
          let value = data[0].rawValue;
          const result = await this.$axios.get(`${this.webService}/validate?response=${value}`, { validateStatus: () => true });
          // if (result.status !== 200) {
          //   console.log(`Failed to verify from service: ${result.status} ${result.statusText}`);
          //   alert("ERROR", result.statusText);
          //   return;
          // }
          //alert(result);
          //alert(result.data.toLowerCase());
          this.verifyStatus = result.data.toLowerCase() === "valid challenge" ? "YES" : "NO";
        }
      } catch (err) {
        alert(err);
      }

    }
  }
  
}
</script>

<style>
  .qrcode-stream-wrapper {
    display: flex;
  }
  .qrcode-stream-camera {
    max-width: 100% !important;
  }


</style>

<style scoped>
  .main {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .title {
    font-size: 20px;
    font-weight: bold;
    margin-bottom: 20px;
  }

  .qr-container {
    display: flex;
    margin-top: 20px;
  }

</style>