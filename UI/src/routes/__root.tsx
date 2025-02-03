import { Header } from "@/components/custom/Header";
import { NavBar } from "@/components/custom/NavBar";
import { SimpleLoader } from "@/components/custom/simpleLoader";
import { ConnectButton } from "@/components/web3/connectButton";
import { Center, Container } from "@chakra-ui/react";
import { Outlet, createRootRoute } from "@tanstack/react-router";
import { useAccount } from "wagmi";

export const Route = createRootRoute({
	loader: () => <SimpleLoader />,
	component: RootLayout,
});

function RootLayout() {
	const { isConnected } = useAccount();

	return (
		<Center>
			<Container
				maxWidth={"3xl"}
				minHeight={"svh"}
				padding={2}
				margin={0}
				borderWidth={"1px"}
				borderColor={"border"}
				rounded={"md"}
				position={"relative"}
				display={"grid"}
				gridTemplateRows={"auto 1fr auto"}
				gap={6}
			>
				<Header />

				{isConnected ? <Outlet /> : <ConnectButton />}

				<NavBar />
			</Container>
		</Center>

		// {import.meta.env.DEV && <TanStackRouterDevtools />}
	);
}
