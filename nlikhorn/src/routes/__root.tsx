import { Header } from "@/components/custom/Header";
import { NavBar } from "@/components/custom/NavBar";
import { ConnectButton } from "@/components/web3/connectButton";
import { Button, Center, Container } from "@chakra-ui/react";
import { Outlet, createRootRoute } from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/router-devtools";
import {
	type Dispatch,
	type SetStateAction,
	createContext,
	useState,
} from "react";
import { useAccount, useDisconnect, useEnsAvatar, useEnsName } from "wagmi";

export const HeadingContext = createContext<{
	heading: string;
	setHeading: Dispatch<string>;
}>({ heading: "Nlik'horn", setHeading: () => "Nlik'horn" });

export const Route = createRootRoute({
	component: RootLayout,
});

function RootLayout() {
	const [heading, setHeading] = useState("Nlik'horn");
	const setTitle = (value: SetStateAction<string>) => {
		document.title = `NLik | ${value}`;
		setHeading(value);
	};

	const { isConnected } = useAccount();

	return (
		<HeadingContext.Provider
			value={{
				heading: heading,
				setHeading: setTitle,
			}}
		>
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
					<Header heading={heading} />

					{isConnected ? <Outlet /> : <ConnectButton />}

					<NavBar />
				</Container>
			</Center>

			{import.meta.env.DEV && <TanStackRouterDevtools />}
		</HeadingContext.Provider>
	);
}
