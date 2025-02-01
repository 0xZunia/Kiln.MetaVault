import { Button } from "@chakra-ui/react";
import { useAccount, useDisconnect } from "wagmi";

export function DisconnectButton() {
	const { isConnected } = useAccount();
	const { disconnect } = useDisconnect();
	return (
		isConnected && <Button onClick={() => disconnect()}>Disconnect</Button>
	);
}
