const routers = {
  mainnet: "0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D",
  bsc: "0x34B03Cb9086d7D758AC55af71584F81A598759FE",

  sepolia: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
  bscTestnet: "0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f",
};

const chainSelectors = {
  mainnet: "5009297550715157269",
  bsc: "11344663589394136015",

  sepolia: "16015286601757825753",
  bscTestnet: "13264668187771770619",
};

const links = {
  mainnet: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
  bsc: "0x404460C6A5EdE2D891e8297795264fDe62ADBB75",
  
  sepolia: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  bscTestnet: "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",
};

const weths = {
  mainnet: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  bsc: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",

  sepolia: "0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534",
  bscTestnet: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
};

const tokens = {
  mainnet: {
    usdt: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  },
  bsc: {
    usdt: "0x55d398326f99059ff775485246999027b3197955",
  },

  sepolia: {
    musdt: "0x9C0Ce9D2cEce3Eb55d3562A0FB8A25b6ea82082d",
    musdc: "0xea485A0BFcD17618296bF85dE46A2e3f13f80f5a",
  },
  bscTestnet: {
    musdt: "0x1317EE60b378062aF66eF8DE4398eA104dc54Db4",
    musdc: "0xbBB6D3FE3d94a12b8C2186Af4Ab279fC277d203c",
  },
}

const targetChains = {
  mainnet: "bsc",
  bsc: "mainnet",

  sepolia: "bscTestnet",
  bscTestnet: "sepolia",
}

const tokenAbi = [
  'function name() view returns (string memory)',
  'function symbol() view returns (string memory)',
  'function decimals() view returns (uint8)',
  'function balanceOf(address owner) view returns (uint256)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function transfer(address to, uint256 amount) returns (bool)',
];

const protocolFee = "10000000000";

module.exports = {
  routers,
  chainSelectors,
  links,
  weths,
  tokens,
  targetChains,
  tokenAbi,
  protocolFee
};
