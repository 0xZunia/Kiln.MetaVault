import { Header } from "@/components/custom/Header";
import { NavBar } from "@/components/custom/NavBar";
import { Center, Container } from "@chakra-ui/react";
import { Outlet, createRootRoute } from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/router-devtools";
import {
	type Dispatch,
	type SetStateAction,
	createContext,
	useState,
} from "react";

export const HeadingContext = createContext<{
	heading: string;
	setHeading: Dispatch<string>;
}>({ heading: "Nlik'horn", setHeading: () => "Nlik'horn" });

export const Route = createRootRoute({
	component: () => {
		const [heading, setHeading] = useState("Nlik'horn");
		const setTitle = (value: SetStateAction<string>) => {
			document.title = `NLik | ${value}`;
			setHeading(value);
		};
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

						<Outlet />

						<NavBar />
					</Container>
				</Center>

				{import.meta.env.DEV && <TanStackRouterDevtools />}
			</HeadingContext.Provider>
		);
	},
});
