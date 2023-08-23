<template>
    <div class="container">
  <div style="display: flex; flex-direction: column; align-items: center; padding: 20px">
    <div>
      <img class="logo" src="~/assets/logo1.png" />
    </div>
    <div v-if="!isVerifier">
      <CButton v-if="!isConnected" color="warning"   @click="connect" >Connect Wallet</CButton>
      <div v-else><h1>Your Account Address: </h1><h3>{{ shortAddress }}</h3></div>
      <Generator  v-if="isConnected" ref="buyer"  :webService="webService" :ticket="ticket" @gotKey="getKey" />          
    </div>
    <Verifier v-else :webService="webService"  />  
    <title>CertiGuard</title>        
    </div>
  </div>
</template>

<style scoped>
  .logo {
    height: 170px;
    margin-bottom: auto;
  }
  @media (max-width: 768px) {
    .logo {
      height: 100px; /* Adjust the size as needed for mobile */
    }
  }
.container {
  min-width: 800px; /* Set your desired maximum width */
  margin: 0 auto; /* Center the component horizontally */
}
</style>

<script>
import { defineComponent } from '@vue/composition-api'
import Generator from './components/Generator.vue'
import Verifier from './components/Verifier.vue'
import { ethers } from "ethers";
import ABI from './assets/abi.json';
import { CButton } from '@coreui/vue';

import '@coreui/coreui/dist/css/coreui.min.css'



const queryString  = window.location.search;
const urlParams = new URLSearchParams(queryString);

const CHAIN_ID = 5432;
const RPC_DEFAULT_ENDPOINT = "https://fhenode.fhenix.io/new/evm";
const BLOCK_EXPLORER = "https://demoexplorer.fhenix.io";
const WEB_SERVICE = "https://ticketing-service-test.azurewebsites.net";
const CONTRACT_ADDRESS = "0x611136338d98aAa1db0E10AAEc3315699279d0dd";

var provider;
var signer;

export default defineComponent({
  components: {Generator, Verifier, CButton},
  setup() {
    
  },
  mounted() {
    let connectedBefore = window.localStorage.getItem('ConnectedBefore');
    if (connectedBefore) {
      this.connect();
    }
  },
  data() {
    return {
      account: "",
      isVerifier: urlParams.has('verifier'),
      webService: WEB_SERVICE,
      ticket: ""
    }
  },
  computed: {
    isConnected() {
      return this.account !== "";
    },
    shortAddress() {
      if (this.isConnected) {
        return this.account;
      }
      return "";
    },    
  },
  methods: {
    async connect() {
      provider = new ethers.BrowserProvider(window.ethereum);
      let accounts = await provider.send("eth_requestAccounts", []);
      if (accounts && accounts.length > 0) {
        this.account = accounts[0];
        try {
          await provider.send('wallet_switchEthereumChain', [{ chainId: `0x${CHAIN_ID.toString(16)}` }]);
        } catch (err) {
          await provider.send('wallet_addEthereumChain', [
            {
                chainId: `0x${CHAIN_ID.toString(16)}`,
                chainName: 'Fhenix Network New',
                rpcUrls: [RPC_DEFAULT_ENDPOINT],
                nativeCurrency: {
                  name: "FHE Token",
                  symbol: "FHE",
                  decimals: 18
                },
                blockExplorerUrls: [BLOCK_EXPLORER]
              }
            ]); 
        }

        try {
          signer = await provider.getSigner();
          window.localStorage.setItem('ConnectedBefore', "1");
          window.localStorage.setItem('ShortAddress', this.shortAddress);
        } catch (err) {
          console.log(err);
        }
        
      }
    },

    async getKey(key) {
      try {
        this.ticket = "";
        const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
        let challenge = await contract.getKeyWithChallenge(`0x${key}`);
        console.log(challenge);
        this.ticket = challenge;
        window.localStorage.setItem('keys',challenge );

      } catch (err) {
        console.log(err);
      }
      this.$refs.buyer.processingTicketDone();      
    }

  }
});
</script>
