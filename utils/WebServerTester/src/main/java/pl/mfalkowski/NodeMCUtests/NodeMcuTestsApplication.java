package pl.mfalkowski.NodeMCUtests;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.base.CaseFormat;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.mustache.MustacheProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;
import org.springframework.web.util.UriBuilder;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.SignalType;
import reactor.util.Logger;
import reactor.util.Loggers;
import reactor.util.function.Tuple2;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.NON_PRIVATE;
import static com.fasterxml.jackson.annotation.PropertyAccessor.FIELD;
import static org.springframework.web.reactive.function.BodyInserters.fromObject;
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

        List<WifiStatusData> lastWifiStatuses;
        String lastWifiStatus;

	    List<String> templateNames;

	    String localIP;
	    String ssid;

	    String softAPssid;
	    String softAPenabled;
	    String softAPIP;
	    int softAPClients;

	    int statusDelayMs;
    }

    static class State {
	    String ssid = "";
	    String password;
	    String status = "";
	    String lastConnectionStatus = "";
	    String localIP = "0.0.0.0";

	    String softAPssid = "";
	    String softAPenabled = "false";
	    String softAPIP = "0.0.0.0";
	    int softAPClients = 0;


	    int statusDelayMs = 0;
    }

    static class Status {
        Wifi wifi;
        SoftAP softAP;

        static class Wifi {
            String ssid;
            String status;
            String lastStatus;
            String localIP;
        }

        static class SoftAP {
            String ssid;
            String enabled;
            String ip;
            int clients;
        }
    }

    private final MustacheProperties mustacheProperties;

    @Autowired
    public NodeMcuTestsApplication(MustacheProperties mustacheProperties) {
        this.mustacheProperties = mustacheProperties;
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
                    .doOnNext(s -> s.wifi.ssid = state.ssid)
                    .doOnNext(s -> s.wifi.lastStatus = state.lastConnectionStatus)
                    .doOnNext(s -> s.wifi.localIP = state.localIP)
                    .doOnNext(s -> s.softAP = new Status.SoftAP())
                    .doOnNext(s -> s.softAP.enabled = state.softAPenabled)
                    .doOnNext(s -> s.softAP.ssid = state.softAPssid)
                    .doOnNext(s -> s.softAP.ip = state.softAPIP)
                    .doOnNext(s -> s.softAP.clients = state.softAPClients),
                Status.class
            ).delayElement(Duration.ofMillis(state.statusDelayMs));


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

	private Function<String, Mono<List<AdminData.WifiStatusData>>> getAdminWifiStatuses =
        currentValue ->
            Flux.fromArray(WifiStatus.values())
                .map(Enum::name)
                .concatWith(Mono.just(""))
                .flatMap(s -> Mono.just(new AdminData.WifiStatusData())
                    .doOnNext(sd -> sd.value = s)
                    .doOnNext(sd -> sd.isCurrent = (Objects.equals(s, currentValue)))
                )
                .collectList();

	private HandlerFunction<ServerResponse> adminGetHandler =
        request ->
            Mono.just(new AdminData())

                .zipWith(getAdminWifiStatuses.apply(state.status))
                .doOnNext(t -> t.getT1().wifiStatuses = t.getT2())
                .map(Tuple2::getT1)
                .doOnNext(data -> data.wifiStatus = state.status)

                .zipWith(getAdminWifiStatuses.apply(state.lastConnectionStatus))
                .doOnNext(t -> t.getT1().lastWifiStatuses = t.getT2())
                .map(Tuple2::getT1)
                .doOnNext(data -> data.lastWifiStatus = state.lastConnectionStatus)

                .doOnNext(data -> data.localIP = state.localIP)

                .doOnNext(data -> data.softAPssid = state.softAPssid)
                .doOnNext(data -> data.softAPenabled = state.softAPenabled)
                .doOnNext(data -> data.softAPIP = state.softAPIP)
                .doOnNext(data -> data.softAPClients = state.softAPClients)

                .doOnNext(data -> data.statusDelayMs = state.statusDelayMs)

                .flatMap(data -> getTemplateNames()
                    .collectList()
                    .doOnNext(templateNames -> data.templateNames = templateNames)
                    .map(t -> data)
                )
                .doOnNext(data -> data.ssid = state.ssid)
                .map(data -> Collections.singletonMap("data", data))
                .flatMap(model -> ServerResponse.ok().render("admin/admin", model));

	private HandlerFunction<ServerResponse> adminPostHandler =
        request ->
            request.formData()
                .doOnNext(form -> state.status = form.getFirst("wifiStatus"))
                .doOnNext(form -> state.lastConnectionStatus = form.getFirst("lastWifiStatus"))
                .doOnNext(form -> state.localIP = form.getFirst("localIP"))
                .doOnNext(form -> state.ssid = form.getFirst("ssid"))
                .doOnNext(form -> state.softAPenabled = form.getFirst("softAPenabled"))
                .doOnNext(form -> state.softAPssid = form.getFirst("softAPssid"))
                .doOnNext(form -> state.softAPIP = form.getFirst("softAPIP"))
                .doOnNext(form -> state.softAPClients = Integer.parseInt(form.getFirst("softAPClients")))
                .doOnNext(form -> state.statusDelayMs = Integer.parseInt(form.getFirst("statusDelayMs")))
                .then(ServerResponse.seeOther(URI.create("/admin")).build());

	private HandlerFunction<ServerResponse> adminGetTemplateHandler =
        request ->
            Flux.fromStream(request.queryParam("name").stream())
                .singleOrEmpty()
                .materialize()
                .flatMap(signal ->
                    signal.getType() == SignalType.ON_COMPLETE
                        ? ServerResponse.badRequest().body(fromObject("'name' query param is missing!"))
                        : getTemplate(signal.get())
                            .flatMap(content -> ServerResponse.ok()
                                .contentType(MediaType.TEXT_PLAIN)
                                .body(fromObject(content))
                            )
                            .onErrorResume(error -> ServerResponse
                                .status(HttpStatus.NOT_FOUND)
                                .body(fromObject("Template '" + signal.get() + "' not found!"))
                            )
                );

	private HandlerFunction<ServerResponse> disconnectHandler =
        request ->
            Mono.just(request)
                .doOnNext(r -> this.state.status = "WL_IDLE_STATUS")
                .doOnNext(r -> this.state.ssid = "")
                .doOnNext(r -> this.state.localIP = "0.0.0.0")
                .doOnNext(r -> this.state.lastConnectionStatus = "WL_IDLE_STATUS")
                .then(ServerResponse.seeOther(
                    UriComponentsBuilder.fromPath("/")
                        .queryParam("message", "You will be disconnected from wifi any second soon!")
                        .build().toUri()
                    )
                    .build()
                );

	private HandlerFunction<ServerResponse> disableAPHandler =
        request ->
            Mono.just(request)
                .doOnNext(r -> this.state.softAPenabled = "false")
                .doOnNext(r -> this.state.softAPClients = 0)
                .doOnNext(r -> this.state.softAPIP = "0.0.0.0")
                .doOnNext(r -> this.state.softAPssid = "")
                .then(ServerResponse.seeOther(
                    UriComponentsBuilder.fromPath("/")
                        .queryParam("message", "Soft AP will be disabled any second soon!")
                        .build().toUri()
                    )
                        .build()
                );

	private HandlerFunction<ServerResponse> enableAPHandler =
        request ->
            Mono.just(request)
                .doOnNext(r -> this.state.softAPenabled = "true")
                .doOnNext(r -> this.state.softAPClients = 1)
                .doOnNext(r -> this.state.softAPIP = "192.168.0.2")
                .doOnNext(r -> this.state.softAPssid = "NODE_MCU")
                .then(ServerResponse.seeOther(URI.create("/")).build());

    @Bean
    RouterFunction<ServerResponse> routes()  {
		return route(GET("/status"), statusHandler)
			.and(route(GET("/"), request -> ServerResponse.ok().render("root")))
            .and(route(GET("/connecting"), request -> ServerResponse.ok().render("connecting")))
			.and(route(POST("/connect"), connectHandler))
            .and(route(POST("/disconnect"), disconnectHandler))
            .and(route(POST("/disable-ap"), disableAPHandler))
            .and(route(POST("/enable-ap"), enableAPHandler))

            .and(route(GET("/admin"), adminGetHandler))
            .and(route(POST("/admin"), adminPostHandler))
            .and(route(GET("/admin/template"), adminGetTemplateHandler));
    }

    @Bean
	ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
		return builder.build()
			.setVisibility(FIELD, NON_PRIVATE);
	}

	private Flux<String> getTemplateNames() {
        var suffix = mustacheProperties.getSuffix();

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        List<Resource> resources;
        try {
            resources = Arrays.asList(resolver.getResources("classpath:/templates/*" + suffix));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        return Flux.fromIterable(resources)
            .map(Resource::getFilename)
            .map(filename -> filename.substring(0, filename.lastIndexOf('.')));
    }

    private final static Pattern templateLinePattern = Pattern.compile("^(?<prefix>\\s*)(?<content>\\S.*)?$");
    private final static Pattern blockContentPattern = Pattern.compile("^\\{\\{>\\s*(?<block>\\S+)\\s*\\}\\}$");

    private Mono<String> getTemplate(String template) {

        return Mono
            .fromCallable(() ->
                this.getClass().getResource("/templates/" + template + mustacheProperties.getSuffix())
            )
            .map(url -> {
                try {
                    return Files.lines(Paths.get(url.toURI()));
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            })
            .single()
            .flatMapMany(Flux::fromStream)
            .map(line -> line.replace("\\", "\\\\"))
            .map(line -> line.replace("\"", "\\\""))
            .map(line -> {
                var matcher = templateLinePattern.matcher(line);
                if (!matcher.matches()) {
                    throw new RuntimeException(String.format("Something wrong with pattern. It doesn't match '%s'", line));
                }
                var prefix = matcher.group("prefix");
                var content = matcher.group("content");
                if (content == null || content.isEmpty()) {
                    return "";
                }
                var blockMatcher = blockContentPattern.matcher(content);
                if (blockMatcher.matches()) {
                    var block = blockMatcher.group("block");
                    var blockCamelCase = CaseFormat.LOWER_UNDERSCORE.converterTo(CaseFormat.LOWER_CAMEL).convert(block);
                    return "    " + prefix + "+ " + blockCamelCase + " +";
                } else {
                    return "    " + prefix + "\"" + content + "\"";
                }
            })
            .filter(l -> !"".equals(l))
            .collect(Collectors.joining("\n", "", ";"));
    }
}
