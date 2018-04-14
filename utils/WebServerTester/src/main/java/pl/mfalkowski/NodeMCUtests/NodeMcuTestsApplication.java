package pl.mfalkowski.NodeMCUtests;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.util.Logger;
import reactor.util.Loggers;
import reactor.util.function.Tuple2;

import java.net.URI;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.NON_PRIVATE;
import static com.fasterxml.jackson.annotation.PropertyAccessor.FIELD;
import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RequestPredicates.POST;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class NodeMcuTestsApplication {

	private final Logger logger = Loggers.getLogger(NodeMcuTestsApplication.class);
	private final State state = new State();

    enum WifiStatus {
        WL_IDLE_STATUS,
        WL_NO_SSID_AVAIL,
        WL_SCAN_COMPLETED,
        WL_CONNECTED,
        WL_CONNECT_FAILED,
        WL_CONNECTION_LOST,
        WL_DISCONNECTED
    }

    static class AdminData {
	    static class WifiStatusData {
	        String value;
	        boolean isCurrent;
        }

	    List<WifiStatusData> wifiStatuses;
	    String wifiStatus;
    }

    static class State {
	    String ssid;
	    String password;
	    String status = "";
    }

    static class Status {
        Wifi wifi;

        static class Wifi {
            String ssid;
            String status;
        }
    }

	public static void main(String[] args) {
		SpringApplication.run(NodeMcuTestsApplication.class, args);
	}

	private HandlerFunction<ServerResponse> statusHandler =
        request ->
            ServerResponse.ok().body(
                Mono.just(new Status())
                    .doOnNext(s -> s.wifi = new Status.Wifi())
                    .doOnNext(s -> s.wifi.status = state.status)
                    .doOnNext(s -> s.wifi.ssid = state.ssid),
                Status.class
            );


	private HandlerFunction<ServerResponse> connectHandler =
		request ->
			request.formData()
                .flatMap(body ->
                    Mono.just(body.getFirst("ssid"))
                        .filter(Objects::nonNull)
                        .doOnNext(s -> logger.info("SSID: {}", s))
                        .doOnNext(s -> state.ssid = s)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No ssid in request!")))
                        .then(Mono.just(body.getFirst("password")))
                        .filter(Objects::nonNull)
                        .doOnNext(p -> logger.info("password: {}", p))
                        .doOnNext(p -> state.password = p)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No password in request!")))
                )
                .then(ServerResponse.seeOther(URI.create("/connecting")).build());

	private HandlerFunction<ServerResponse> adminGetHandler =
        request ->
            Mono.just(new AdminData())
                .zipWith(
                    Flux.fromArray(WifiStatus.values())
                        .map(Enum::name)
                        .flatMap(s -> Mono
                            .just(new AdminData.WifiStatusData())
                            .doOnNext(sd -> sd.value = s)
                            .doOnNext(sd -> sd.isCurrent = (Objects.equals(s, state.status)))
                        )
                        .collectList()
                )
                .doOnNext(t -> t.getT1().wifiStatuses = t.getT2())
                .map(Tuple2::getT1)
                .doOnNext(data -> data.wifiStatus = state.status)
                .map(data -> Collections.singletonMap("data", data))
                .flatMap(model -> ServerResponse.ok().render("admin/admin", model));

	private HandlerFunction<ServerResponse> adminPostHandler =
        request ->
            request.formData()
                .doOnNext(form -> state.status = form.getFirst("wifiStatus"))
                .then(ServerResponse.seeOther(URI.create("/admin")).build());

    @Bean
    RouterFunction<ServerResponse> routes()  {
		return route(GET("/status"), statusHandler)
			.and(
				route(GET("/"), request -> ServerResponse.ok().render("root"))
			)
            .and(route(GET("/connecting"), request -> ServerResponse.ok().render("connecting")))
			.and(route(POST("/connect"), connectHandler))
            .and(route(GET("/admin"), adminGetHandler))
            .and(route(POST("/admin"), adminPostHandler));
    }

    @Bean
	ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
		return builder.build()
			.setVisibility(FIELD, NON_PRIVATE);
	}
}
