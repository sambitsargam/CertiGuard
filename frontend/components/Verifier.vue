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
      <h1>{{ fetchedName }}</h1>
    </div>
  </div>
</template>

<script>
import { QrcodeStream } from 'vue-qrcode-reader'
import { CButton, CSpinner } from '@coreui/vue';
import axios from 'axios';
import YESAnimation from '../assets/yes.json'
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
          console.log(data);
          this.allowScan = false;
          let value = data[0].rawValue;
          const result = await this.$axios.get(`${this.webService}/validate?response=${value}`, { validateStatus: () => true });
          const response = await axios.get('https://certi-1d8a0-default-rtdb.firebaseio.com/tickets.json');
          const jsonData = response.data;

          let recipientName = null;

          for (const key in jsonData) {
            if (jsonData.hasOwnProperty(key)) {
              const ticketId = jsonData[key].ticket;
              if (ticketId === value) {
                recipientName = jsonData[key].recipient;
                break; // Exit loop since we found the target ticket
              }
            }
          }
          if (recipientName) {
             this.name = recipientName;
          } else {
            this.name = "Ticket not found";
          }
          const fetchedName = this.name;
          this.verifyStatus = result.data.toLowerCase() === "valid challenge" ? "YES" : "NO";
        }
      } catch (err) {
        alert(err);
      }

    },

    // // creating a function to test the data
    // async fetchname() {
    //   try {
    //     const response = await axios.get('https://certi-1d8a0-default-rtdb.firebaseio.com/tickets.json');
    //     const jsonData = response.data;

    //     const targetTicketId = "0x17885244b9d68d66b76df6b6d00ec83b5209ca0f9e4310b484f10029032b650e44aff0b8badbdba8321c84ea9ca50f704182f723";
    //     let recipientName = null;

    //     for (const key in jsonData) {
    //       if (jsonData.hasOwnProperty(key)) {
    //         const ticketId = jsonData[key].ticket;
    //         if (ticketId === targetTicketId) {
    //           recipientName = jsonData[key].recipient;
    //           break; // Exit loop since we found the target ticket
    //         }
    //       }
    //     }

    //     if (recipientName) {
    //       console.log(`Recipient for ticket ${targetTicketId}: ${recipientName}`);
    //     } else {
    //       console.log(`Ticket ${targetTicketId} not found.`);
    //     }
    //   } catch (error) {
    //     console.error("Error fetching data:", error);
    //   }
    // }

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