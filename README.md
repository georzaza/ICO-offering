## 1. What is this project? 
In short, this project is about a Crowdsale on Ethereum blockchain. 
It was developed as an answer to: https://github.com/Blockchain-for-Developers/sp18-midterm-p1
See the contracts, they are Heavily Commented. 
Also see the `hand-testing` file until real tests are added (except for the queue tests)


## 2. How to run

#### Installation
```
git clone https://github.com/georzaza/ICO-offering.git
cd ICO-offering
npm install
```

#### Running the tests
1nd way: `truffle develop` and then `test`
2rd way: `ganache-cli` and then `truffle test`

#### Running Interactively
Run `ganacle-cli` (or maybe ganache AppImage for a GUI), then `truffle console` and finally `deploy`. This will give you a Node terminal where you can run Javascript commands. A better way to run it is just `truffle develop` and then `deploy`.
