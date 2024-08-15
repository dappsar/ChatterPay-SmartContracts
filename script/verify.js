async function main() {
    const contractAddress = "0x961bf3bf61d3446907E0Db83C9c5D958c17A94f6";
    const initialAccount = "0xe54b48F8caF88a08849dCdDE3D3d41Cd6D7ab369";

    await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: [initialAccount],
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });