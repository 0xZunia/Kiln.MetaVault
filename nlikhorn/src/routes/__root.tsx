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
			<>
				<HeadingContext.Provider
					value={{
						heading: heading,
						setHeading: setTitle,
					}}
				>
					<Center height={"100svh"} position={"relative"}>
						<Container maxWidth={"xl"} boxSize={"full"} padding={2}>
							<Header heading={heading} />

							<Outlet />

							<NavBar />
						</Container>
					</Center>

					{import.meta.env.DEV && <TanStackRouterDevtools />}
				</HeadingContext.Provider>
			</>
		);
	},
});
