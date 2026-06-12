import Foundation

protocol InquiryRepositoryProtocol {
    func createInquiry(_ body: InquiryBody) async throws -> Inquiry
    func createReservation(_ body: ReservationBody) async throws -> Reservation
    func myInquiries() async throws -> [Inquiry]
    func myReservations() async throws -> [Reservation]
}

final class InquiryRepository: InquiryRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func createInquiry(_ body: InquiryBody) async throws -> Inquiry {
        let envelope: APIEnvelope<Inquiry> = try await client.send(Endpoints.createInquiry(body))
        return envelope.data
    }

    func createReservation(_ body: ReservationBody) async throws -> Reservation {
        let envelope: APIEnvelope<Reservation> = try await client.send(Endpoints.createReservation(body))
        return envelope.data
    }

    func myInquiries() async throws -> [Inquiry] {
        let envelope: Paginated<Inquiry> = try await client.send(Endpoints.myInquiries())
        return envelope.data
    }

    func myReservations() async throws -> [Reservation] {
        let envelope: Paginated<Reservation> = try await client.send(Endpoints.myReservations())
        return envelope.data
    }
}
