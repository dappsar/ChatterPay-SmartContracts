const hre = require("hardhat");

async function main() {
    const [signer] = await hre.ethers.getSigners();

    // Direcciones de los contratos desplegados (reemplazar con las direcciones reales)
    const WETH_ADDRESS = "0xAb9c2e04398ad9e9369360de77c011516a5aef99";
    const USDT_ADDRESS = "0xfE2af1D55F7da5eD75f63aF5fD61136e1F92c4f9";
    const SIMPLE_SWAP_ADDRESS = "0x7c38F638Bb821Cf8E5A8c59460f5C6a992a9cBAE";

    // Conectar a los contratos
    const weth = await hre.ethers.getContractAt("WETH", WETH_ADDRESS, signer);
    const usdt = await hre.ethers.getContractAt("USDT", USDT_ADDRESS, signer);
    const simpleSwap = await hre.ethers.getContractAt("SimpleSwap", SIMPLE_SWAP_ADDRESS, signer);

    console.log("Conectado a los contratos:");
    console.log("WETH:", WETH_ADDRESS);
    console.log("USDT:", USDT_ADDRESS);
    console.log("SimpleSwap:", SIMPLE_SWAP_ADDRESS);

    // Función auxiliar para imprimir balances
    async function printBalances(address) {
        const wethBalance = await weth.balanceOf(address);
        const usdtBxalance = await usdt.balanceOf(address);
        console.log(`Balances de ${address}:`);
        console.log(`WETH: ${hre.ethers.utils.formatEther(wethBalance)} WETH`);
        console.log(`USDT: ${hre.ethers.utils.formatEther(usdtBalance)} USDT`);
    }

    // Verificar balances iniciales
    console.log("\nBalances iniciales:");
    await printBalances(signer.address);

    // Realizar swap de WETH a USDT
    const wethToSwap = hre.ethers.utils.parseEther("1"); // Swap 1 WETH
    console.log(`\nRealizando swap de ${hre.ethers.utils.formatEther(wethToSwap)} WETH a USDT...`);

    // Aprobar WETH para el swap
    const wethApproveTX = await weth.approve(SIMPLE_SWAP_ADDRESS, wethToSwap, {
        nonce: await signer.getTransactionCount() // Incrementar el nonce manualmente
    });
    await wethApproveTX.wait();
    
    // Realizar el swap
    await simpleSwap.swapWETHforUSDT(wethToSwap, {
        gasLimit: 500000
    });
    console.log("Swap de WETH a USDT completado.");

    // Verificar balances después del primer swap
    console.log("\nBalances después del swap WETH a USDT:");
    await printBalances(signer.address);

    // Realizar swap de USDT a WETH
    const usdtToSwap = hre.ethers.utils.parseEther("100"); // Swap 100 USDT
    console.log(`\nRealizando swap de ${hre.ethers.utils.formatEther(usdtToSwap)} USDT a WETH...`);

    const usdtApproveTX = await usdt.approve(SIMPLE_SWAP_ADDRESS, usdtToSwap);
    await usdtApproveTX.wait();

    await simpleSwap.swapUSDTforWETH(usdtToSwap, {
        gasLimit: 500000
    });

    console.log("Swap de USDT a WETH completado.");

    // Verificar balances finales
    console.log("\nBalances finales:");
    await printBalances(signer.address);

    // Verificar reservas del pool
    const [wethReserve, usdtReserve] = await simpleSwap.getReserves();
    console.log("\nReservas del pool:");
    console.log(`WETH: ${hre.ethers.utils.formatEther(wethReserve)} WETH`);
    console.log(`USDT: ${hre.ethers.utils.formatEther(usdtReserve)} USDT`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });