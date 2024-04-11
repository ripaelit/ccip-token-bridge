const routers = {
  mainnet: "0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D",
  sepolia: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",

  bsc: "0x34B03Cb9086d7D758AC55af71584F81A598759FE",
  bscTestnet: "0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f",

  arbitrumOne: "0x141fa059441E0ca23ce184B6A78bafD2A517DdE8",
  arbitrumSepolia: "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165",

  optimisticEthereum: "0x3206695CaE29952f4b0c22a169725a865bc8Ce0f",
  optimismSepolia: "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57",
};

const chainSelectors = {
  mainnet: "5009297550715157269",
  sepolia: "16015286601757825753",

  bsc: "11344663589394136015",
  bscTestnet: "13264668187771770619",

  arbitrumOne: "4949039107694359620",
  arbitrumSepolia: "3478487238524512106",

  optimisticEthereum: "3734403246176062136",
  optimismSepolia: "5224473277236331295",

};

const links = {
  mainnet: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
  sepolia: "0x779877A7B0D9E8603169DdbD7836e478b4624789",

  bsc: "0x404460C6A5EdE2D891e8297795264fDe62ADBB75",
  bscTestnet: "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",

  arbitrumOne: "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
  arbitrumSepolia: "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E",

  optimisticEthereum: "0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6",
  optimismSepolia: "0xE4aB69C077896252FAFBD49EFD26B5D171A32410",
};

const weths = {
  mainnet: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  sepolia: "0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534",

  bsc: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  bscTestnet: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",

  arbitrumOne: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
  arbitrumSepolia: "0xE591bf0A0CF924A0674d7792db046B23CEbF5f34",

  optimisticEthereum: "0x4200000000000000000000000000000000000006",
  optimismSepolia: "0x4200000000000000000000000000000000000006",
};

const usdts = {
  mainnet: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  sepolia: "0x9C0Ce9D2cEce3Eb55d3562A0FB8A25b6ea82082d",

  bsc: "0x55d398326f99059ff775485246999027b3197955",
  bscTestnet: "0x1317EE60b378062aF66eF8DE4398eA104dc54Db4",

  arbitrumOne: "0x8B34a2E3ADa9e7CAE1a3964053946501925C71ED",
  arbitrumSepolia: "0xA588F78eefB8d0212308141EB3d4702051953363",

  optimisticEthereum: "0xEaABaE5350E58f73d199bDB0E5D7Ac9bd11cDF86",
  optimismSepolia: "0x9a76206A606d730990B740304be6fa91F3c08ecA"
}

const dstChains = {
  mainnet: "bsc",
  bsc: "mainnet",

  arbitrumOne: "optimisticEthereum",
  optimisticEthereum: "arbitrumOne",

  sepolia: "bscTestnet",
  bscTestnet: "sepolia",

  arbitrumSepolia: "optimismSepolia",
  optimismSepolia: "arbitrumSepolia"
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
  usdts,
  dstChains,
  tokenAbi,
  protocolFee
};
