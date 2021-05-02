// Change this address to match your deployed contract!
const contract_address = "0xa5b70b3f9e02b2d0b85E10042a76b1A7F397Cc6b";

const dApp = {
  ethEnabled: function() {
    // If the browser has MetaMask installed
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      window.ethereum.enable();
      return true;
    }
    return false;
  },
  //pinata_api_key
  submitToken: async function() {
    const name = $("#dapp-name").val();
    const email = $("#dapp-email").val();
    const address_key = $("#dapp-address-key").val();

    try {
      const image_hash = await image_upload_response.json();
      const image_uri = `ipfs://${image_hash.IpfsHash}`;

      M.toast({ html: `Success. Image located at ${image_uri}.` });
      M.toast({ html: "Uploading JSON..." });

      const reference_json = JSON.stringify({
        pinataContent: { name, description, image: image_uri },
        pinataOptions: {cidVersion: 1}
      });

      const json_upload_response = await fetch("https://api.pinata.cloud/pinning/pinJSONToIPFS", {
        method: "POST",
        mode: "cors",
        headers: {
          "Content-Type": "application/json",
          pinata_api_key,
          pinata_secret_api_key
        },
        body: reference_json
      });

      M.toast({ html: `Success. Reference URI located at ${reference_uri}.` });
      M.toast({ html: "Sending to blockchain..." });

      
      if ($("#dapp-opensource-toggle").prop("checked")) {
        this.contract.methods.openSourceWork(reference_uri).send({from: this.accounts[0]})
        .on("receipt", (receipt) => {
          M.toast({ html: "Transaction Mined! Refreshing UI..." });
          location.reload();
        });
      } else {
        this.contract.methods.BHCoinSale().send({from: this.accounts[0]})
        .on("receipt", (receipt) => {
          M.toast({ html: "Transaction Mined! Refreshing UI..." });
          location.reload();
        });
      }

    } catch (e) {
      alert("ERROR:", JSON.stringify(e));
    }
  },
  main: async function() {
    // Initialize web3
    if (!this.ethEnabled()) {
      alert("Please install MetaMask to use this dApp!");
    }

    this.accounts = await window.web3.eth.getAccounts();

    this.BHCoinSaleABI = await (await fetch("./BHCoinSale.json")).json();

    this.contract = new window.web3.eth.Contract(
      this.BHCoinSaleABI,
      contract_address,
      { defaultAccount: this.accounts[0] }
    );
    console.log("Contract object", this.contract);
  }
};

dApp.main();
