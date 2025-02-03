import { IconButton } from "@chakra-ui/react";
import { IoMdExit } from "react-icons/io";
import { useAccount, useDisconnect } from "wagmi";

export function DisconnectButton() {
	const { isConnected } = useAccount();
	const { disconnect } = useDisconnect();
	return (
		isConnected && (
			<IconButton
				variant={"subtle"}
				colorPalette={"red"}
				onClick={() => disconnect()}
			>
				<IoMdExit />
			</IconButton>
		)
	);
}
