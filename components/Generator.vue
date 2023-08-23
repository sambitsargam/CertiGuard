<template>
  <div class="main">
    <div v-if="!certificateGenerated" class="form-section">
      <h2>Create a Certificate</h2>
      <form @submit.prevent="generateCertificate" class="certificate-form">
        <div class="form-group">
          <label for="recipientName">Recipient's Name:</label>
          <input v-model="recipientName" id="recipientName" required />
        </div>
        <div class="form-group">
          <label for="certificateDetails">Certificate Details:</label>
          <textarea v-model="certificateDetails" id="certificateDetails" rows="4" required></textarea>
        </div>
        <button type="submit">Save the Details</button>
      </form>
    </div>
    <div v-else>
      <div class="qr-section">
        <CButton color="success" :disabled="purchasing" @click="purchaseTicket">{{ purchaseButtonTitle }}</CButton>
        <div v-if="hasTicket && !purchasing" ref="qrContainer" class="qr-container">
          <div class="ticket-with-qr">
            <img class="ticket-image" src="~/assets/certi.png" />
            <div class="certificate-text">
              <p>{{ recipientName }}</p>
            </div>
            <qrcode-vue class="qr-code" render-as="svg" background="none" :value="ticket" :size="50" level="H" />
          </div>
        </div>
        <CButton class="download-button" color="primary" size="sm" @click="downloadAsPNG">Download Certificate</CButton>

        <div v-if="purchasing" class="loading-section">
          <CSpinner style="width: 50px; height: 50px" color="warning" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import QrcodeVue from 'qrcode.vue'
import { CButton, CSpinner } from '@coreui/vue';
import html2canvas from 'html2canvas';


export default {
  name: 'Generator',
  components: { QrcodeVue, CButton, CSpinner },
  props: {
    webService: String,
    ticket: String
  },
  data() {
    return {
      recipientName: '',
      certificateDetails: '',
      certificateGenerated: false,
      purchasing: false,
      ticketData: ""
    };
  },
  computed: {
    hasTicket() {
      return (this.ticket !== "" && this.ticket !== undefined);
    },
    purchaseButtonTitle() {
      return this.purchasing ? "Please wait..." : (!this.hasTicket ? "Generate Certificate" : "Refresh QR");
    },
    shortAddress() {
      return this.account;
    },
  },
  methods: {
    processingTicketDone() {
      this.purchasing = false;
    },
    refreshTicket() {
      this.$emit('gotKey', this.ticketData);
    },
    async downloadAsPNG() {
      const qrContainer = this.$refs.qrContainer;

      try {
        const canvas = await html2canvas(qrContainer);
        const pngDataUrl = canvas.toDataURL('image/png');

        const a = document.createElement('a');
        a.href = pngDataUrl;
        a.download = 'certificate.png';
        a.click();
      } catch (error) {
        console.error('Error generating PNG:', error);
      }
    },
    async purchaseTicket() {
      try {
        this.purchasing = true;
        const encodedData = await this.$axios.get(`${this.webService}/create`);
        if (encodedData.status !== 200) {
          console.log(`Failed to encrypt number from service: ${encodedData.status} ${encodedData.statusText}`);
          return;
        }
        this.ticketData = encodedData.data;
        window.localStorage.setItem('MyTicket', this.ticketData);
        this.$emit('gotKey', this.ticketData);
        const savedShortAddress = window.localStorage.getItem('ShortAddress');
        const certificateRecipient = window.localStorage.getItem('certificateRecipient');
        const certificateDetails = window.localStorage.getItem('certificateDetails');
        const apiEndpoint = 'https://certi-1d8a0-default-rtdb.firebaseio.com/tickets.json';
        const postData = {
          ticket: this.ticketData,
          address: savedShortAddress,
          recipient: certificateRecipient,
          details: certificateDetails
        };
        const response = await this.$axios.post(apiEndpoint, postData);
        if (response.status === 200) {
          this.purchasing = false;
        }
      } catch (err) {
        console.log(err);
      }
    },
    async generateCertificate() {
      // Save the details to local storage
      localStorage.setItem('certificateRecipient', this.recipientName);
      localStorage.setItem('certificateDetails', this.certificateDetails);

      // SEND SUCCESS MESSAGE
      this.certificateGenerated = true;
    }
  }
};
</script>

<style scoped>
.main {
  display: flex;
  margin-top: 2px;
  min-height: 100vh;
  background-color: #f0f0f0;
  font-family: Arial, sans-serif;
}

.form-section,
.qr-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 20px;
  text-align: center;
}

.certificate-form {
  max-width: 400px;
  width: 100%;
  margin-top: 1px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  font-weight: bold;
}

input,
textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 3px;
}

button {
  background-color: #007bff;
  color: #fff;
  border: none;
  padding: 8px 12px;
  border-radius: 3px;
  cursor: pointer;
}

.qr-container {
  position: relative;
  text-align: center;
  margin-top: 20px;
}

.download-button {
  margin-top: 10px;
}

.ticket-with-qr {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.ticket-image {
  width: auto;
  height: auto;
  max-width: 100%;
}

.qr-code {
  width: 20%;
  height: auto;
  position: absolute;
  bottom: 0;
  left: 0;
  margin-bottom: 5.5%;
  margin-left: 1.8%;
  transform: translate(10px, 10px);
  /* Add some padding to the QR code */
}


.certificate-text p {
  margin: 0;
  font-size: 40px;
  font-weight: bold;
  color: #000;
  text-align: center;
}

.certificate {
  position: relative;
  display: flex;
  align-items: flex-end;
  margin-bottom: 20px;
}

.certificate-text {
  position: absolute;
  top: 55%;
  /* Vertically center the text */
  left: 50%;
  /* Horizontally center the text */
  transform: translate(-50%, -50%);
  /* Adjust for centering */
  padding: 10px;
  background-color: rgba(255, 255, 255, 0.8);
  text-align: center;
  /* Center-align the text content */
}



.loading-section {
  margin-top: 60px;
}</style>