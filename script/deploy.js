const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    let nonce = await deployer.getTransactionCount();

    console.log("Desplegando contratos con la cuenta:", deployer.address);
    console.log("Nonce inicial:", nonce);

    try {
        // Desplegar USDT
        console.log("Desplegando USDT...");
        const USDT = await hre.ethers.getContractFactory("USDT");
        const usdt = await USDT.deploy(deployer.address, { nonce: nonce++ });
        await usdt.deployed();
        console.log("Contrato USDT desplegado en:", usdt.address);

        // Desplegar WETH
        console.log("Desplegando WETH...");
        const WETH = await hre.ethers.getContractFactory("WETH");
        const weth = await WETH.deploy(deployer.address, { nonce: nonce++ });
        await weth.deployed();
        console.log("Contrato WETH desplegado en:", weth.address);

        // Desplegar SimpleSwap
        console.log("Desplegando SimpleSwap...");
        const SimpleSwap = await hre.ethers.getContractFactory("SimpleSwap");
        const simpleSwap = await SimpleSwap.deploy(weth.address, usdt.address, { nonce: nonce++ });
        await simpleSwap.deployed();
        console.log("Contrato SimpleSwap desplegado en:", simpleSwap.address);

        // Añadir liquidez inicial al SimpleSwap
        const wethAmount = hre.ethers.utils.parseEther("1000"); // 1000 WETH
        const usdtAmount = hre.ethers.utils.parseEther("2700000"); // 2,700,000 USDT

        console.log("Mintendo tokens para el deployer...");
        await weth.mint(deployer.address, wethAmount, { nonce: nonce++ });
        await usdt.mint(deployer.address, usdtAmount, { nonce: nonce++ });

        // Verificar balances después de acuñar
        const wethBalance = await weth.balanceOf(deployer.address);
        const usdtBalance = await usdt.balanceOf(deployer.address);
        console.log(`Balance de WETH del deployer: ${hre.ethers.utils.formatEther(wethBalance)} WETH`);
        console.log(`Balance de USDT del deployer: ${hre.ethers.utils.formatEther(usdtBalance)} USDT`);

        console.log("Aprobando WETH para SimpleSwap...");
        await weth.approve(simpleSwap.address, wethAmount, { nonce: nonce++ });
        console.log("Aprobando USDT para SimpleSwap...");
        await usdt.approve(simpleSwap.address, usdtAmount, { nonce: nonce++ });

        // Verificar aprobaciones
        const wethAllowance = await weth.allowance(deployer.address, simpleSwap.address);
        const usdtAllowance = await usdt.allowance(deployer.address, simpleSwap.address);
        console.log(`Aprobación de WETH para SimpleSwap: ${hre.ethers.utils.formatEther(wethAllowance)} WETH`);
        console.log(`Aprobación de USDT para SimpleSwap: ${hre.ethers.utils.formatEther(usdtAllowance)} USDT`);

        console.log("Añadiendo liquidez al SimpleSwap...");
        const addLiquidityTx = await simpleSwap.addLiquidity(wethAmount, usdtAmount, {
            nonce: nonce++,
            gasLimit: 500000 // Establecer un límite de gas manual
        });
        await addLiquidityTx.wait();
        console.log("Liquidez inicial añadida al SimpleSwap");

        // Verificar reservas
        const [wethReserve, usdtReserve] = await simpleSwap.getReserves();
        console.log(`Reserva de WETH en SimpleSwap: ${hre.ethers.utils.formatEther(wethReserve)} WETH`);
        console.log(`Reserva de USDT en SimpleSwap: ${hre.ethers.utils.formatEther(usdtReserve)} USDT`);


        // Verificar los contratos
        console.log("Verificando contratos...");
        await verifyContract(usdt.address, [deployer.address], "USDT");
        await verifyContract(weth.address, [deployer.address], "WETH");
        await verifyContract(simpleSwap.address, [weth.address, usdt.address], "SimpleSwap");

    } catch (error) {
        console.error("Error durante el despliegue:", error);
        if (error.transaction) {
            console.error("Transacción fallida:", error.transaction);
            console.error("Razón del fallo:", error.reason);
        }
    }
}

async function verifyContract(address, constructorArguments, contractName) {
    try {
        await hre.run("verify:verify", {
            address: address,
            constructorArguments: constructorArguments,
        });
        console.log(`${contractName} verificado con éxito`);
    } catch (error) {
        console.log(`Error verificando ${contractName}:`, error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });