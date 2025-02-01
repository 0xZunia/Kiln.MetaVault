import { Header } from "@/components/custom/Header";
import { NavBar } from "@/components/custom/NavBar";
import { Center, Container, Loader } from "@chakra-ui/react";
import { Outlet, createRootRoute } from "@tanstack/react-router";

export const Route = createRootRoute({
	loader: () => <Loader />,
	component: () => {
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

					<Outlet />

					<NavBar />
				</Container>
			</Center>
		);
	},
});
// {import.meta.env.DEV && <TanStackRouterDevtools />}
