const routers = {
  mainnet: "0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D",
  bsc: "0x34B03Cb9086d7D758AC55af71584F81A598759FE",
  arbitrumOne: "0x141fa059441E0ca23ce184B6A78bafD2A517DdE8",

  sepolia: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
  bscTestnet: "0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f",
  arbitrumSepolia: "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165"
};

const chainSelectors = {
  mainnet: "5009297550715157269",
  bsc: "11344663589394136015",
  arbitrumOne: "4949039107694359620",

  sepolia: "16015286601757825753",
  bscTestnet: "13264668187771770619",
  arbitrumSepolia: "3478487238524512106"
};

const links = {
  mainnet: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
  bsc: "0x404460C6A5EdE2D891e8297795264fDe62ADBB75",
  arbitrumOne: "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
  
  sepolia: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  bscTestnet: "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",
  arbitrumSepolia: "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E"
};

const weths = {
  mainnet: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  bsc: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  arbitrumOne: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",

  sepolia: "0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534",
  bscTestnet: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
  arbitrumSepolia: "0xE591bf0A0CF924A0674d7792db046B23CEbF5f34"
};

const tokens = {
  mainnet: {
    usdt: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  },
  bsc: {
    usdt: "0x55d398326f99059ff775485246999027b3197955",
  },
  arbitrumOne: {
    usdt: "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
  },

  sepolia: {
    musdt: "0x9C0Ce9D2cEce3Eb55d3562A0FB8A25b6ea82082d",
    musdc: "0xea485A0BFcD17618296bF85dE46A2e3f13f80f5a",
  },
  bscTestnet: {
    musdt: "0x1317EE60b378062aF66eF8DE4398eA104dc54Db4",
    musdc: "0xbBB6D3FE3d94a12b8C2186Af4Ab279fC277d203c",
  },
  arbitrumSepolia: {
    musdt: "0x7e1A5b7E08305c45AA0d51D756B222749B73eAcA",
    musdc: "0x394F0c6446a5279b7D8fB185846C8484a49F058f",
  }
}

const targetChains = {
  mainnet: ["bsc", "arbitrumOne"],
  bsc: ["mainnet", "arbitrumOne"],
  arbitrumOne: ["mainnet", "bsc"],

  sepolia: ["bscTestnet", "arbitrumSepolia"],
  bscTestnet: ["sepolia", "arbitrumSepolia"],
  arbitrumSepolia: ["sepolia", "bscTestnet"]
}

const tokenAbi = [
  'function name() view returns (string memory)',
  'function symbol() view returns (string memory)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address owner) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function transferFrom(address sender, address recipient, uint256 amount) returns (bool)',
  'function mint(address _to, uint256 _amount)',
  'function burn(address _to, uint256 _amount)',
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
